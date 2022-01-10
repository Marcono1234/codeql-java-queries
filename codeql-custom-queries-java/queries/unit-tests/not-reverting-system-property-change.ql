/**
 * Finds test classes which change system properties, but do not seem to revert their
 * changes again. Such test implementations are error-prone because they might affect
 * the execution of subsequent unrelated test methods.
 */

import java

abstract class SystemPropertyChangingCall extends MethodAccess {
    abstract string getPropertyName();

    abstract MethodAccess getRevertingCall();
}

class SystemSetPropertyCall extends SystemPropertyChangingCall {
    string propertyName;

    SystemSetPropertyCall() {
        exists(Method m |
            m = getMethod()
            and m.getDeclaringType() instanceof TypeSystem
            and propertyName = getArgument(0).(CompileTimeConstantExpr).getStringValue()
            and m.hasName("setProperty")
        )
    }

    override
    string getPropertyName() {
        result = propertyName
    }

    override
    MethodAccess getRevertingCall() {
        // Reverts change with `clearProperty` call
        result.(SystemClearPropertyCall).getPropertyName() = getPropertyName()
        or
        // Or uses `setProperty` to restore previous value or set constant
        // Limit this to successor of call (instead of complete test class) to reduce false positives
        result.(SystemSetPropertyCall).getPropertyName() = getPropertyName()
        and result != this
        and result.getControlFlowNode() = getControlFlowNode().getASuccessor+()
    }
}

class SystemClearPropertyCall extends SystemPropertyChangingCall {
    string propertyName;
    Method revertingMethod;

    SystemClearPropertyCall() {
        exists(Method m |
            m = getMethod()
            and m.getDeclaringType() instanceof TypeSystem
            and propertyName = getArgument(0).(CompileTimeConstantExpr).getStringValue()
            and revertingMethod.getDeclaringType() instanceof TypeSystem
            and m.hasName("clearProperty")
        )
    }

    override
    string getPropertyName() {
        result = propertyName
    }

    override
    MethodAccess getRevertingCall() {
        result.(SystemSetPropertyCall).getPropertyName() = getPropertyName()
    }
}

from TestClass testClass, SystemPropertyChangingCall call, string propertyName
where
    call.getEnclosingCallable().getDeclaringType+() = testClass.(TopLevelType)
    and propertyName = call.getPropertyName()
    and not exists(MethodAccess otherCall |
        // Consider reverting call in complete test class in case it is in separate teardown method
        otherCall.getEnclosingCallable().getDeclaringType+() = testClass
        and (
            // otherCall reverts the changes
            otherCall = call.getRevertingCall()
            // Or call is itself the reverting call for otherCall
            or call = otherCall.(SystemPropertyChangingCall).getRevertingCall()
        )
    )
select call, "Changes system property '" + propertyName + "', but does not revert it again"
