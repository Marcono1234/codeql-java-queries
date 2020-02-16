/**
 * Tries to find incorrect usage of Log4j 2's Logger where logging methods accepting 
 * an Object are called with a Throwable. This only logs `throwable.toString()` while 
 * the caller likely wanted to log the exception with stack trace.
 */

import java

abstract class LoggerMethod extends Method {}

class Log4j1LoggerMethods extends LoggerMethod {
    Log4j1LoggerMethods() {
        (
            getDeclaringType().hasQualifiedName("org.apache.log4j", "Category")
            and exists (string s | getSignature() = s |
                s = "debug(java.lang.Object)"
                or s = "info(java.lang.Object)"
                or s = "warn(java.lang.Object)"
                or s = "error(java.lang.Object)"
                or s = "fatal(java.lang.Object)"
            )
        )
        or (
            getDeclaringType().hasQualifiedName("org.apache.log4j", "Logger")
            and exists (string s | getSignature() = s |
                s = "trace(java.lang.Object)"
            )
        )
    }
}

class Log4j2LoggerMethods extends LoggerMethod {
    Log4j2LoggerMethods() {
        getDeclaringType().hasQualifiedName("org.apache.logging.log4j", "Logger")
        and exists (string s | getSignature() = s |
            s = "trace(java.lang.Object)"
            or s = "debug(java.lang.Object)"
            or s = "info(java.lang.Object)"
            or s = "warn(java.lang.Object)"
            or s = "error(java.lang.Object)"
            or s = "fatal(java.lang.Object)"
        )
    }
}

predicate isLoggerMethodOrOverrides(Method m) {
    m instanceof LoggerMethod
    or exists (LoggerMethod logM | m.overrides(logM))
}

from MethodAccess call
where
    isLoggerMethodOrOverrides(call.getMethod())
    and call.getAnArgument().getType() instanceof ThrowableType
select call
