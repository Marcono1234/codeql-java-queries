/**
 * Finds `catch` clauses which, in addition to throwing an exception
 * (potentially the caught one), also log information about the caught
 * exception. E.g.:
 * ```
 * try {
 *     ...
 * } catch (IOException ioException) {
 *     logger.error("Action failed", ioException);
 *     throw ioException;
 * }
 * ```
 * This creates duplicate and probably irritating information in the
 * log file because in addition to the exception being logged here, the
 * caller likely logs it as well as part of exception handling.
 *
 * Instead the logging call should be removed and either a new exception
 * with detailed message and the caught exception as cause should be
 * thrown, or the `catch` clause should be removed completely:
 * ```
 * try {
 *     ...
 * } catch (IOException ioException) {
 *     throw new MyException("Action failed", ioException);
 * }
 * ```
 */

import java

abstract class LoggingCall extends MethodAccess {
    abstract predicate isDebugLogging();
    
    /**
     * Whether this call returns the provided exception (if any).
     * This detects logging method usage such as the following:
     * ```
     * throw logger.throwing(myException);
     * ```
     *
     * The default implementation of this predicate never holds.
     */
    // Note: Predicate is currently not used
    predicate returnsException() {
        none()
    }
}

class TypeJavaUtilLogger extends Class {
    TypeJavaUtilLogger() {
        hasQualifiedName("java.util.logging", "Logger")
    }
}

class JavaUtilLoggingLevel extends Field {
    JavaUtilLoggingLevel() {
        getDeclaringType().hasQualifiedName("java.util.logging", "Level")
    }
    
    predicate isDebugLevel() {
        hasName([
            "CONFIG",
            "FINE", "FINER", "FINEST",
            "ALL" // Should not actually be used in logging calls, but is < FINEST
        ])
    }
}

class JavaUtilLoggingCall extends LoggingCall {
    private string methodName;
    
    JavaUtilLoggingCall() {
        exists(Method m |
            m = getMethod()
            and m.getDeclaringType().getASourceSupertype*() instanceof TypeJavaUtilLogger
            and methodName = m.getName()
        |
            methodName = [
                "config",
                "entering", "exiting",
                "fine", "finer", "finest",
                "info",
                "log", "logp", "logrb",
                "severe",
                "throwing",
                "warning"
            ]
        )
    }
    
    override
    predicate isDebugLogging() {
        methodName = [
            "config",
            "entering", "exiting",
            "fine", "finer", "finest",
            "throwing"
        ]
        or (
            methodName = ["log", "logp", "logrb"]
            and getArgument(0).(FieldAccess).getField().(JavaUtilLoggingLevel).isDebugLevel()
        )
    }
}

/**
 * [`java.lang.System.Logger`](https://docs.oracle.com/en/java/javase/15/docs/api/java.base/java/lang/System.Logger.html)
 * (added in Java 9)
 */
class TypeJavaSystemLogger extends Interface {
    TypeJavaSystemLogger() {
        hasQualifiedName("java.lang", "System$Logger")
    }
}

class SystemLoggerLevel extends EnumConstant {
    SystemLoggerLevel() {
        getDeclaringType().hasQualifiedName("java.lang", "System$Logger$Level")
    }
    
    predicate isDebugLevel() {
        hasName([
            "ALL", // Should not actually be used in logging calls, but is < TRACE
            "TRACE",
            "DEBUG"
        ])
    }
}

class SystemLoggerCall extends LoggingCall {
    SystemLoggerCall() {
        exists(Method m |
            m = getMethod()
            and m.getDeclaringType().getASourceSupertype*() instanceof TypeJavaSystemLogger
        |
            m.hasName("log")
        )
    }
    
    override
    predicate isDebugLogging() {
        getArgument(0).(FieldAccess).getField().(SystemLoggerLevel).isDebugLevel()
    }
}

class TypeLog4j1Logger extends Class {
    TypeLog4j1Logger() {
        hasQualifiedName("org.apache.log4j", "Category")
    }
}

class Log4j1Priority extends Field {
    Log4j1Priority() {
        getDeclaringType().hasQualifiedName("org.apache.log4j", ["Priority", "Level"])
        or getDeclaringType().hasQualifiedName("org.apache.log4j.helpers", "UtilLoggingLevel")
    }
    
    predicate isDebugLevel() {
        hasName([
            "DEBUG",
            "ALL", // Should not actually be used in logging calls, but is < FINEST
            "TRACE",
            "CONFIG",
            "FINE", "FINER", "FINEST"
        ])
    }
}

class Log4j1LoggingCall extends LoggingCall {
    private string methodName;
    
    Log4j1LoggingCall() {
        exists(Method m |
            m = getMethod()
            and m.getDeclaringType().getASourceSupertype*() instanceof TypeLog4j1Logger
            and methodName = m.getName()
        |
            methodName = [
                "debug",
                "error",
                "fatal",
                "info",
                "l7dlog", "log",
                "warn",
                "trace" // Declared by subclass `Logger`
            ]
        )
    }
    
    override
    predicate isDebugLogging() {
        methodName = [
            "debug",
            "trace" // Declared by subclass `Logger`
        ]
        or (
            methodName = ["l7dlog", "log"]
            // `getAnArgument()` because priority is not always first argument
            and getAnArgument().(FieldAccess).getField().(Log4j1Priority).isDebugLevel()
        )
    }
}

class TypeLog4j2Logger extends Interface {
    TypeLog4j2Logger() {
        hasQualifiedName("org.apache.logging.log4j", "Logger")
        or hasQualifiedName("org.apache.logging.log4j.spi", "ExtendedLogger")
    }
}

class Log4j2Level extends Field {
    Log4j2Level() {
        getDeclaringType().hasQualifiedName("org.apache.logging.log4j", "Level")
    }
    
    predicate isDebugLevel() {
        hasName([
            "ALL", // Should not actually be used in logging calls, but is < TRACE
            "DEBUG",
            "TRACE"
        ])
    }
}

class Log4j2LoggingCall extends LoggingCall {
    private string methodName;
    
    Log4j2LoggingCall() {
        exists(Method m |
            m = getMethod()
            and m.getDeclaringType().getASourceSupertype*() instanceof TypeLog4j2Logger
            and methodName = m.getName()
        |
            methodName = [
                "catching",
                "debug",
                "entry",
                "error",
                "exit",
                "fatal",
                "info",
                "log", "logMessage", "printf",
                "throwing",
                "trace", "traceEntry", "traceExit",
                "warn",
                // From ExtendedLogger
                "logIfEnabled", "logMessage"
            ]
        )
    }
    
    override
    predicate isDebugLogging() {
        methodName = [
            "debug",
            "entry", "exit",
            "trace", "traceEntry", "traceExit"
        ]
        or (
            methodName = [
                "log", "logMessage", "printf",
                // `catching` and `throwing` without Level parameter log at ERROR level
                // by default, see LOG4J2-3020 and LOG4J2-3021
                "catching", "throwing", // Allow specifying a level
                // From ExtendedLogger
                "logIfEnabled", "logMessage"
            ]
            // `getAnArgument()` because level is not always first argument
            and getAnArgument().(FieldAccess).getField().(Log4j2Level).isDebugLevel()
        )
    }
    
    override
    predicate returnsException() {
        methodName = "throwing"
    }
}

class TypeLog4j2LogBuilder extends Interface {
    TypeLog4j2LogBuilder() {
        hasQualifiedName("org.apache.logging.log4j", "LogBuilder")
    }
}

private MethodAccess getQualifier(MethodAccess call) {
    result = call.getQualifier()
}

class Log4j2LogBuilderLoggingCall extends LoggingCall {
    Log4j2LogBuilderLoggingCall() {
        exists(Method m |
            m = getMethod()
            and m.getDeclaringType().getASourceSupertype*() instanceof TypeLog4j2LogBuilder
        |
            m.hasName([
                "log",
                "withThrowable"
            ])
        )
    }
    
    override
    predicate isDebugLogging() {
        // LogBuilder should be used in method call chain; check qualifiers to
        // find Logger method which created LogBuilder
        exists(MethodAccess loggerMethodCall, Method loggerMethod |
            loggerMethod.getDeclaringType().getASourceSupertype*() instanceof TypeLog4j2Logger
            and loggerMethodCall = getQualifier+(this)
            and loggerMethod = loggerMethodCall.getMethod()
        |
            loggerMethod.hasStringSignature(["atDebug()", "atTrace()"])
            or (
                loggerMethod.hasStringSignature("atLevel(Level)")
                and loggerMethodCall.getArgument(0).(FieldAccess).getField().(Log4j2Level).isDebugLevel()
            )
        )
    }
}

class TypeApacheCommonsLog extends Interface {
    TypeApacheCommonsLog() {
        hasQualifiedName("org.apache.commons.logging", "Log")
    }
}

class ApacheCommonsLoggingCall extends LoggingCall {
    private string methodName;
    
    ApacheCommonsLoggingCall() {
        exists(Method m |
            m = getMethod()
            and m.getDeclaringType().getASourceSupertype*() instanceof TypeApacheCommonsLog
            and methodName = m.getName()
        |
            methodName = [
                "debug",
                "error",
                "fatal",
                "info",
                "trace",
                "warn"
            ]
        )
    }
    
    override
    predicate isDebugLogging() {
        methodName = ["debug", "trace"]
    }
}

class TypeJBossLogger extends RefType {
    TypeJBossLogger() {
        // `org.jboss.logging.Logger` in some implementations like JBoss Application Server 4.0.4 did not implement `BasicLogger`
        hasQualifiedName("org.jboss.logging", ["BasicLogger", "Logger"])
    }
}

class JBossLoggerLevel extends EnumConstant {
    JBossLoggerLevel() {
        getDeclaringType().hasQualifiedName("org.jboss.logging", "Logger$Level")
    }
    
    predicate isDebugLevel() {
        hasName([
            "DEBUG",
            "TRACE"
        ])
    }
}

class JBossLoggingCall extends LoggingCall {
    private string methodName;
    
    JBossLoggingCall() {
        exists(Method m |
            m = getMethod()
            and m.getDeclaringType().getASourceSupertype*() instanceof TypeJBossLogger
            and methodName = m.getName()
        |
            methodName = [
                "debug", "debugf", "debugv",
                "error", "errorf", "errorv",
                "fatal", "fatalf", "fatalv",
                "info", "infof", "infov",
                "log", "logf", "logv",
                "trace", "tracef", "tracev",
                "warn", "warnf", "warnv"
            ]
        )
    }
    
    override
    predicate isDebugLogging() {
        methodName.matches(["debug%", "trace%"])
        or (
            methodName.matches("log%s")
            // `getAnArgument()` because logger level is not always first argument
            and getAnArgument().(FieldAccess).getField().(JBossLoggerLevel).isDebugLevel()
        )
    }
}

class TypeSlf4jLogger extends RefType {
    TypeSlf4jLogger() {
        hasQualifiedName("org.slf4j", "Logger")
        or hasQualifiedName("org.slf4j.spi", "LocationAwareLogger")
        or hasQualifiedName("org.slf4j.ext", "XLogger")
        or hasQualifiedName("org.slf4j.cal10n", "LocLogger")
    }
}

class Slf4jLocationAwareLoggerLevel extends Field {
    Slf4jLocationAwareLoggerLevel() {
        getDeclaringType().hasQualifiedName("org.slf4j.spi", "LocationAwareLogger")
    }
    
    predicate isDebugLevel() {
        hasName([
            "DEBUG_INT",
            "TRACE_INT"
        ])
    }
}

class Slf4jXLoggerLevel extends EnumConstant {
    Slf4jXLoggerLevel() {
        getDeclaringType().hasQualifiedName("org.slf4j.ext", "XLogger$Level")
    }
    
    predicate isDebugLevel() {
        hasName([
            "DEBUG",
            "TRACE"
        ])
    }
}

class Slf4jLoggingCall extends LoggingCall {
    private string methodName;
    
    Slf4jLoggingCall() {
        exists(Method m |
            m = getMethod()
            and m.getDeclaringType().getASourceSupertype*() instanceof TypeSlf4jLogger
            and methodName = m.getName()
        |
            methodName = [
                "debug",
                "error",
                "info",
                "trace",
                "warn",
                "log", // LocationAwareLogger
                // XLogger:
                "catching",
                "entry",
                "exit",
                "throwing"
            ]
        )
    }
    
    override
    predicate isDebugLogging() {
        methodName = [
            "debug", "trace",
            "entry", "exit"
        ]
        // LocationAwareLogger:
        or (
            methodName = "log"
            and getArgument(2).(FieldAccess).getField().(Slf4jLocationAwareLoggerLevel).isDebugLevel()
        )
        // XLogger
        or (
            methodName = "log"
            and getArgument(0).(FieldAccess).getField().(Slf4jXLoggerLevel).isDebugLevel()
        )
    }
    
    override
    predicate returnsException() {
        // XLogger.throwing(...)
        methodName = "throwing"
    }
}

class TypeSlf4jLoggingEventBuilder extends Interface {
    TypeSlf4jLoggingEventBuilder() {
        hasQualifiedName("org.slf4j.spi", "LoggingEventBuilder")
    }
}

class Slf4jLoggingEventBuilderLoggingCall extends LoggingCall {
    Slf4jLoggingEventBuilderLoggingCall() {
        exists(Method m |
            m = getMethod()
            and m.getDeclaringType().getASourceSupertype*() instanceof TypeSlf4jLoggingEventBuilder
        |
            m.hasName([
                "addArgument",
                "addKeyValue",
                "log",
                "setCause"
            ])
        )
    }
    
    override
    predicate isDebugLogging() {
        // LoggingEventBuilder should be used in method call chain; check qualifiers to
        // find Logger method which created LoggingEventBuilder
        exists(MethodAccess loggerMethodCall, Method loggerMethod |
            loggerMethod.getDeclaringType().getASourceSupertype*() instanceof TypeSlf4jLogger
            and loggerMethodCall = getQualifier+(this)
            and loggerMethod = loggerMethodCall.getMethod()
        |
            loggerMethod.hasStringSignature(["atDebug()", "atTrace()"])
        )
    }
}

/**
 * Logger type of Google's [flogger](https://github.com/google/flogger)
 */
class TypeFloggerLogger extends Class {
    TypeFloggerLogger() {
        hasQualifiedName("com.google.common.flogger", "AbstractLogger")
    }
}

class TypeFloggerApi extends Interface {
    TypeFloggerApi() {
        hasQualifiedName("com.google.common.flogger", "LoggingApi")
    }
}

class FloggerLoggingCall extends LoggingCall {
    FloggerLoggingCall() {
        exists(Method m |
            m = getMethod()
            and m.getDeclaringType().getASourceSupertype*() instanceof TypeFloggerApi
        |
            m.hasName([
                "log",
                "logVarargs",
                "with",
                "withCause"
            ])
        )
    }
    
    override
    predicate isDebugLogging() {
        // Flogger should be used in method call chain; check qualifiers to
        // find Logger method which created fluent logger
        exists(MethodAccess loggerMethodCall, Method loggerMethod |
            loggerMethod.getDeclaringType().getASourceSupertype*() instanceof TypeFloggerLogger
            and loggerMethodCall = getQualifier+(this)
            and loggerMethod = loggerMethodCall.getMethod()
        |
            loggerMethod.hasStringSignature([
                "atConfig()",
                "atFine()", "atFiner()", "atFinest()"
            ])
            or (
                loggerMethod.hasStringSignature("at(Level)")
                // Flogger uses `java.util.logging` log level
                and loggerMethodCall.getArgument(0).(FieldAccess).getField().(JavaUtilLoggingLevel).isDebugLevel()
            )
        )
    }
}

private predicate referencesVariable(Expr expr, Variable var) {
    expr.(VarAccess).getVariable() = var
    or exists(Member m |
        (
            m = expr.(MethodAccess).getMethod() and referencesVariable(expr.(MethodAccess).getQualifier(), var)
            or m = expr.(FieldAccess).getField() and referencesVariable(expr.(FieldAccess).getQualifier(), var)
            or m = expr.(MemberRefExpr).getReferencedCallable() and referencesVariable(expr.(MemberRefExpr).getQualifier(), var)
        )
        // Ignore if instance is used for static member access (which itself is bad code style)
        and not m.isStatic()
    )
    // Or lambda expression whose body references the variable
    or exists(Expr nestedExpr |
        nestedExpr.getEnclosingCallable() = expr.(LambdaExpr).asMethod()
        and referencesVariable(nestedExpr, var)
    )
}

/*
 * Currently considers a logging call and any `throw` statement as requirements for
 * a result.
 * This could later be made more strict by requiring that the thrown exception is either
 * the same as the caught one (LoggingCall.returnsException() can help with that) or
 * that it wraps the caught one.
 * However, this query might not have to be that strict. If an exception is thrown anyways,
 * the code should normally make sure to set the caught exception as cause, in which
 * case the additional logging would be redundant again.
 */
from CatchClause catchClause, Variable exceptionVar, LoggingCall loggingCall, Argument loggingArg, ThrowStmt throwStmt
where
    // Make sure that (any) exception is rethrown
    throwStmt.getEnclosingStmt+() = catchClause
    and exceptionVar = catchClause.getVariable().getVariable()
    and loggingCall.getAnEnclosingStmt() = catchClause
    and loggingArg = loggingCall.getAnArgument()
    and referencesVariable(loggingArg, exceptionVar)
    // Ignore debug logging
    and not loggingCall.isDebugLogging()
select loggingCall, "Logging call references caught exception $@ despite an exception being rethrown $@", loggingArg, "here", throwStmt, "here"
