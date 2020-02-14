/**
 * Tries to find incorrect usage of Log4j 2's Logger where logging methods accepting 
 * an Object are called with a Throwable. This only logs `throwable.toString()` while 
 * the caller likely wanted to log the exception with stack trace.
 */

import java

predicate isLoggingMethod(string signature) {
    signature = "trace(java.lang.Object)"
    or signature = "debug(java.lang.Object)"
    or signature = "info(java.lang.Object)"
    or signature = "warn(java.lang.Object)"
    or signature = "error(java.lang.Object)"
    or signature = "fatal(java.lang.Object)"
}

class LoggerType extends RefType {
    LoggerType() {
        hasQualifiedName("org.apache.logging.log4j", "Logger")
    }
}

from MethodAccess call, Method method
where
    call.getMethod() = method
    and method.getDeclaringType() instanceof LoggerType
    and isLoggingMethod(method.getSignature())
    and call.getAnArgument().getType() instanceof ThrowableType
select call
