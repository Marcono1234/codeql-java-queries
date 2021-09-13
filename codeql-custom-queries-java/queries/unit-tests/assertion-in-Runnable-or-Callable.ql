/**
 * Finds assertion method calls from inside a method overriding `Runnable.run`
 * or `Callable.call`. Because these interfaces are often used in combination
 * with multi-threading, it is likely that the assertion call will be performed
 * by a different thread than the one executing the enclosing test method.
 * Care must be take to ensure that any exceptions thrown inside that different
 * thread are properly handled and not just discarded by the default uncaught
 * exception handler of the thread.
 * 
 * See [SonarSource rule RSPEC-2186](https://rules.sonarsource.com/java/tag/junit/RSPEC-2186).
 */

import java
import lib.TestsQLInterop

class RunnableRunMethod extends Method {
    RunnableRunMethod() {
        getDeclaringType().getASourceSupertype+().hasQualifiedName("java.lang", "Runnable")
        and hasStringSignature("run()")
    }
}

class CallableCallMethod extends Method {
    CallableCallMethod() {
        getDeclaringType().getASourceSupertype+().hasQualifiedName("java.util.concurrent", "Callable")
        and hasStringSignature("call()")
    }
}

// TODO: Could reduce false positives by checking if there is a `try` statement which covers the
// complete body and stores the exception somewhere, but such an implementation is still error-prone

from Method method, MethodAccess assertionCall
where
    (
        method instanceof RunnableRunMethod
        or method instanceof CallableCallMethod
    )
    and assertionCall.getEnclosingCallable() = method
    and assertionCall.getMethod() instanceof AssertionMethod
select assertionCall, "Assertion call might be made by different thread"
