/**
 * Finds _format string_ arguments, such as the first argument to `String.format`,
 * which are created from user-controlled input. Format strings can allow
 * denial of service attacks through the use of very large _width_ values.
 * 
 * This query is based on [this tweet](https://twitter.com/WouterCoekaerts/status/1372538099322982400)
 * by Wouter Coekaerts.
 *
 * @kind path-problem
 */

import java
import semmle.code.java.StringFormat
import semmle.code.java.dataflow.FlowSources
import DataFlow::PathGraph

abstract class FormatStringSink extends DataFlow::Node {
}

class FormatCallSink extends FormatStringSink {
    FormatCallSink() {
        exists (StringFormatMethod formatMethod, MethodAccess formatCall |
            formatCall.getMethod().getSourceDeclaration().getASourceOverriddenMethod*() = formatMethod
            and formatCall.getArgument(formatMethod.getFormatStringIndex()) = this.asExpr()
        )
    }
}

class Log4j2StringFormattedMessageSink extends FormatStringSink {
    Log4j2StringFormattedMessageSink() {
        exists(ConstructorCall constructorCall, Constructor constructor, int formatStringIndex |
            constructorCall.getConstructor() = constructor
            and constructor.getDeclaringType().hasQualifiedName("org.apache.logging.log4j.message", [
                "StringFormattedMessage",
                // FormattedMessage determines on its own whether MessageFormat or format string is used
                "FormattedMessage"
            ])
            and formatStringIndex = [0, 1]
            and constructor.getParameterType(formatStringIndex) instanceof TypeString
        |
            this.asExpr() = constructorCall.getArgument(formatStringIndex)
        )
    }
}

class TypeLog4j2Logger extends Interface {
    TypeLog4j2Logger() {
        hasQualifiedName("org.apache.logging.log4j", "Logger")
    }
}

class Log4j2PrintfLogMethodSink extends FormatStringSink {
    Log4j2PrintfLogMethodSink() {
        exists(MethodAccess call, Method m, int formatStringIndex |
            m = call.getMethod()
        |
            m.getDeclaringType() instanceof TypeLog4j2Logger
            and formatStringIndex = [1, 2]
            and m.hasName("printf")
            and m.getParameterType(formatStringIndex) instanceof TypeString
            and call.getArgument(formatStringIndex) = this.asExpr()
        )
    }
}

/*
 * LocalizedMessage creates FormattedMessage if key is not found in bundle, see
 * https://github.com/apache/logging-log4j2/blob/5edf43758f104affad9842753e66be173fc4d68a/log4j-api/src/main/java/org/apache/logging/log4j/message/LocalizedMessage.java#L195-L197
 */
class Log4j2LocalizedMessageSink extends FormatStringSink {
    Log4j2LocalizedMessageSink() {
        exists(ConstructorCall constructorCall, Constructor constructor, int formatStringIndex |
            constructorCall.getConstructor() = constructor
            and constructor.getDeclaringType().hasQualifiedName("org.apache.logging.log4j.message", "LocalizedMessage")
            and constructor.getParameterType(formatStringIndex) instanceof TypeString
            and (
                // (formatString, ...)
                (
                    formatStringIndex = 0
                    and (
                        constructor.getParameterType(1) instanceof TypeObject
                        or constructor.getParameterType(1).(Array).getComponentType() instanceof TypeObject
                    )
                )
                // (locale, formatString, ...)
                // (bundle, formatString, ...)
                // (baseName, formatString, ...)
                or (
                    formatStringIndex = 1
                    and constructor.getParameterType(0).(RefType).hasName([
                        "Locale",
                        "ResourceBundle",
                        "String"
                    ])
                )
                // (bundle, locale, formatString, ...)
                // (baseName, locale, formatString, ...)
                or (
                    formatStringIndex = 2
                    and constructor.getParameterType(1).(RefType).hasName("Locale")
                )
            )
        |
            this.asExpr() = constructorCall.getArgument(formatStringIndex)
        )
    }
}

/**
 * Creates a Log4j 2 logger which uses `Formatter` format strings for logging.
 */
class Log4j2FormatterLoggerCreatingCall extends MethodAccess {
    Log4j2FormatterLoggerCreatingCall() {
        exists(Method m |
            m = getMethod()
            and m.getDeclaringType().hasQualifiedName("org.apache.logging.log4j", "LogManager")
        |
            m.hasName("getFormatterLogger")
            or (
                m.hasName("getLogger")
                and getAnArgument().getType().(RefType).hasQualifiedName("org.apache.logging.log4j.message", [
                    "StringFormatterMessageFactory",
                    // Creates FormattedMessage which determines on its own whether MessageFormat or format string is used
                    "FormattedMessageFactory",
                    // LocalizedMessage creates FormattedMessage if key is not found in bundle, see
                    // https://github.com/apache/logging-log4j2/blob/5edf43758f104affad9842753e66be173fc4d68a/log4j-api/src/main/java/org/apache/logging/log4j/message/LocalizedMessage.java#L195-L197
                    "LocalizedMessageFactory"
                ])
            )
        )
    }
}

class TypeCharSequence extends Interface {
    TypeCharSequence() {
        hasQualifiedName("java.lang", "CharSequence")
    }
}

// TODO: Not tested yet
/**
 * Sink being the argument of a log method on a logger created using `Log4j2FormatterLoggerCreatingCall`.
 */
class Log4j2FormattingLoggerLogMethodCallSink extends FormatStringSink {
    Log4j2FormattingLoggerLogMethodCallSink() {
        exists(MethodAccess call, Method m, int indexOffset, int messageIndex |
            m = call.getMethod()
            and (
                call.getQualifier() instanceof Log4j2FormatterLoggerCreatingCall
                or call.getQualifier().(FieldRead).getField().getAnAssignedValue() instanceof Log4j2FormatterLoggerCreatingCall
            )
            and call.getArgument(indexOffset + messageIndex) = this.asExpr()
        |
            (
                (
                    messageIndex = 0
                    and m.getParameterType(messageIndex) instanceof TypeObject
                )
                or (
                    messageIndex = [0, 1]
                    and (
                        m.getParameterType(messageIndex) instanceof TypeString
                        or m.getParameterType(messageIndex) instanceof TypeCharSequence
                    )
                )
            )
            and (
                indexOffset = 0
                and m.hasName([
                    "debug",
                    "error",
                    "fatal",
                    "info",
                    "trace",
                    "traceEntry",
                    "traceExit",
                    "warn"
                ])
                // First parameter is Level
                or indexOffset = 1
                and m.hasName([
                    "log"
                ])
            )
        )
    }
}

class FormatStringInjectionConfig extends TaintTracking::Configuration {
    FormatStringInjectionConfig() {
        this = "FormatStringInjectionConfig"
    }

    override predicate isSource(DataFlow::Node source) {
        source instanceof RemoteFlowSource
    }

    override predicate isSanitizerOut(DataFlow::Node node) {
        // Ignore primitive types and wrappers which are unlikely exploitable
        exists(Type t | t = node.getType() |
            t instanceof PrimitiveType
            or t instanceof BoxedType
        )
    }

    override predicate isSink(DataFlow::Node sink) {
        sink instanceof FormatStringSink
    }
}

from FormatStringInjectionConfig config, DataFlow::PathNode source, DataFlow::PathNode sink
where
    config.hasFlowPath(source, sink)
select sink.getNode(), source, sink, "Format string is created using user-controlled $@.", source.getNode(), "data"
