/**
 * Finds calls of `Throwable.printStackTrace()`.
 * They should be avoided because users of the class cannot configure 
 * where the stack trace will be printed. And additionally there is no 
 * indication where the method was called, making it difficult to tell 
 * where based on the printed stack trace where the exception was 
 * handled.
 */

import java

from MethodAccess call, Method method
where
    call.getMethod() = method 
    and method.getDeclaringType() instanceof ThrowableType
    and method.getSignature() = "printStackTrace()"
    // Make sure this is not a `super.printStackTrace()` call
    and not exists (Method enclosing | enclosing.callsSuper(method))
select call
