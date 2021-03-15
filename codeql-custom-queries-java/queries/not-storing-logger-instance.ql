/**
 * Finds cases where logger instances are always retrieved with the same name or class,
 * instead of the logger instances being stored in a static or instance field. E.g.:
 * ```
 * public void performTask() {
 *     try {
 *         ...
 *     } catch (IOException exception) {
 *         // Retrieves logger every time instead of storing it in field
 *         LogManager.getLogger().error("Task failed", exception);
 *     }
 * }
 * ```
 * For efficiency and simplicity logger instances should be stored in an instance or
 * static field.
 */

import java

abstract class ConstantLoggerRetrievingCall extends MethodAccess {
}

/**
 * Checks if the expression is or reads a constant value.
 * 
 * When a call for retrieving a logger uses a non-constant value, e.g.
 * is reading from parameter, then that method call should not be considered
 * by this query.
 */
predicate isConstantValue(Expr expr) {
    expr instanceof Literal
    or expr instanceof TypeLiteral
    or expr.isCompileTimeConstant()
    or exists (Variable var | expr = var.getAnAccess() |
        var.isFinal()
        and isConstantValue(var.getInitializer())
    )
}

// https://docs.oracle.com/en/java/javase/15/docs/api/java.logging/java/util/logging/Logger.html#getLogger(java.lang.String)
class JdkUtilLoggerCall extends ConstantLoggerRetrievingCall {
    JdkUtilLoggerCall() {
        exists (Method m | m = getMethod() |
            m.getDeclaringType().hasQualifiedName("java.util.logging", "Logger")
            and m.isStatic()
            and m.hasName("getLogger")
            and isConstantValue(getArgument(0))
        )
    }
}

// https://docs.oracle.com/en/java/javase/15/docs/api/java.base/java/lang/System.html#getLogger(java.lang.String)
class JdkSystemLoggerCall extends ConstantLoggerRetrievingCall {
    JdkSystemLoggerCall() {
        exists (Method m | m = getMethod() |
            m.getDeclaringType() instanceof TypeSystem
            and m.isStatic()
            and m.hasName("getLogger")
            and isConstantValue(getArgument(0))
        )
    }
}

// https://logging.apache.org/log4j/1.2/apidocs/index.html
class Log4j1LogManagerCall extends ConstantLoggerRetrievingCall {
    Log4j1LogManagerCall() {
        exists (Method m | m = getMethod() |
            m.getDeclaringType().hasQualifiedName("org.apache.log4j", "LogManager")
            and m.isStatic()
            and m.hasName("getLogger")
            and isConstantValue(getArgument(0))
        )
    }
}

// https://logging.apache.org/log4j/1.2/apidocs/org/apache/log4j/Logger.html
class Log4j1LoggerCall extends ConstantLoggerRetrievingCall {
    Log4j1LoggerCall() {
        exists (Method m | m = getMethod() |
            m.getDeclaringType().hasQualifiedName("org.apache.log4j", "Logger")
            and m.isStatic()
            and m.hasName("getLogger")
            and isConstantValue(getArgument(0))
        )
    }
}

// https://logging.apache.org/log4j/2.x/log4j-api/apidocs/org/apache/logging/log4j/LogManager.html
class Log4j2LogManagerCall extends ConstantLoggerRetrievingCall {
    Log4j2LogManagerCall() {
        exists (Method m | m = getMethod() |
            m.getDeclaringType().hasQualifiedName("org.apache.logging.log4j", "LogManager")
            and m.isStatic()
            and (
                // Methods using caller class for getting logger
                m.hasStringSignature([
                    "getFormatterLogger()",
                    "getLogger()",
                    "getLogger(MessageFactory)"
                ])
                // Methods with name parameter
                or (
                    m.hasStringSignature([
                        "getFormatterLogger(Class<?>)",
                        "getFormatterLogger(Object)",
                        "getFormatterLogger(String)",
                        "getLogger(Class<?>)",
                        "getLogger(Class<?>, MessageFactory)",
                        "getLogger(Object)",
                        "getLogger(Object, MessageFactory)",
                        "getLogger(String)",
                        "getLogger(String, MessageFactory)"
                    ])
                    and isConstantValue(getArgument(0))
                )
            )
        )
    }
}

// http://www.slf4j.org/apidocs/org/slf4j/LoggerFactory.html
class Slf4jLoggerFactoryCall extends ConstantLoggerRetrievingCall {
    Slf4jLoggerFactoryCall() {
        exists (Method m | m = getMethod() |
            m.getDeclaringType().hasQualifiedName("org.slf4j", "LoggerFactory")
            and m.isStatic()
            and m.hasName("getLogger")
            and isConstantValue(getArgument(0))
        )
    }
}

from ConstantLoggerRetrievingCall loggerRetrievingCall
where
    // Ignore if logger is created in static or instance initializer
    not loggerRetrievingCall.getEnclosingCallable() instanceof InitializerMethod
    // Ignore initialization of fields happening in constructor
    and not exists (Field f, RefType constructedType |
        f.getAnAssignedValue() = loggerRetrievingCall
        and loggerRetrievingCall.getEnclosingCallable().(Constructor).getDeclaringType() = constructedType
        and constructedType.getASourceSupertype*() = f.getDeclaringType()
    )
    // Ignore test classes, which sometimes modify loggers to intercept log messages
    and not loggerRetrievingCall.getEnclosingCallable().getDeclaringType() instanceof TestClass
select loggerRetrievingCall, "Dynamically retrieves logger"
