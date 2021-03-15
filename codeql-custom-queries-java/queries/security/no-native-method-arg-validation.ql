/**
 * Finds potential cases of missing validation for native method arguments.
 * Usually native methods perform no or only little validation, so calling
 * one with arguments which have not been validated could allow exploiting it.
 * This is especially problematic for native methods accepting memory addresses.
 */

import java
import semmle.code.java.dataflow.TaintTracking

predicate isPubliclyVisible(RefType t) {
    t.isPublic()
    and (
        not exists (t.getEnclosingType())
        or isPubliclyVisible(t.getEnclosingType())
    )
}

class SafeNativeMethod extends Method {
    SafeNativeMethod() {
        // Assume that all public JDK methods are safe
        exists (string packagePrefix |
            (packagePrefix = "java" or packagePrefix = "javax")
            and getDeclaringType().getPackage().getName().indexOf(packagePrefix) = 0
        )
        and isPublic()
        and isPubliclyVisible(getDeclaringType())
    }
}

class NativeCallConfiguration extends TaintTracking::Configuration {
    NativeCallConfiguration() {
        this = "NativeCallConfiguration"
    }

    // Source: Parameter of public method
    override predicate isSource(DataFlow::Node source) {
        exists(Callable callable |
            source.asParameter().getCallable() = callable
            and callable.isPublic()
            and isPubliclyVisible(callable.getDeclaringType())
        )
    }

    // Sink: Integer argument of native method
    override predicate isSink(DataFlow::Node sink) {
        sink.getType() instanceof IntegralType
        and exists(MethodAccess call, Method m |
            m = call.getMethod()
            and m.isNative()
            and not m instanceof SafeNativeMethod
            and call.getAnArgument() = sink.asExpr()
        )
    }

    // Sanitizer: Comparison expression
    // False positives: Collections of valid memory addresses, ...
    // False negatives: Comparison to test if cached buffer is large enough
    //      (negative buffer size is always smaller than cached buffer size), ...
    override predicate isSanitizerOut(DataFlow::Node node) {
        exists (ComparisonExpr compExpr |
            node.asExpr() = compExpr.getAnOperand()
        )
    }
}

from DataFlow::Node src, DataFlow::Node sink
where
    exists (NativeCallConfiguration config | config.hasFlow(src, sink))
select src, sink
