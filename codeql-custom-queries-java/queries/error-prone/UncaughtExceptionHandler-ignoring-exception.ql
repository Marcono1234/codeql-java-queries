/**
 * Finds implementations of `Thread.UncaughtExceptionHandler` which discard the uncaught
 * exception. Such a behavior is error-prone because it makes diagnosing runtime exceptions
 * more difficult.
 */

import java

class UncaughtExceptionMethod extends Method {
    UncaughtExceptionMethod() {
        getDeclaringType().hasQualifiedName("java.lang", "Thread$UncaughtExceptionHandler")
        and hasStringSignature("uncaughtException(Thread, Throwable)")
    }
}

from Method exceptionHandlingMethod, Parameter throwableParam
where
    exceptionHandlingMethod.fromSource()
    and exceptionHandlingMethod.getSourceDeclaration().getASourceOverriddenMethod*() instanceof UncaughtExceptionMethod
    and not exceptionHandlingMethod.isAbstract()
    and throwableParam = exceptionHandlingMethod.getParameter(1)
    and not throwableParam.getAnAccess() instanceof RValue
select throwableParam, "Throwable parameter is ignored"
