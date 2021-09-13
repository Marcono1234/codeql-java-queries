/**
 * Finds `ThreadLocal.get()` calls which appear to check whether a value is
 * set by comparing the result with `null`, but do not `remove` or `set` a
 * different value afterwards.
 *
 * There is currently no way to check if a ThreadLocal value is set without
 * initializing it in case it is not set. It is therefore likely desired to
 * call `remove()` after such a check to clear the initialized (by default
 * to `null`) value.
 *
 * See also [JDK-6630585](https://bugs.openjdk.java.net/browse/JDK-6630585)
 */

import java
import semmle.code.java.dataflow.DataFlow

class TypeThreadLocal extends Class {
    TypeThreadLocal() {
        // Consider subtypes to cover InheritableThreadLocal
        getSourceDeclaration().getASourceSupertype*().hasQualifiedName("java.lang", "ThreadLocal")
    }
}

class GetMethod extends Method {
    GetMethod() {
        getDeclaringType() instanceof TypeThreadLocal
        and hasStringSignature("get()")
    }
}

class SetMethod extends Method {
    SetMethod() {
        getDeclaringType() instanceof TypeThreadLocal
        and hasName("set")
        and getNumberOfParameters() = 1
    }
}

class RemoveMethod extends Method {
    RemoveMethod() {
        getDeclaringType() instanceof TypeThreadLocal
        and hasStringSignature("remove()")
    }
}

from Variable threadLocalVar, MethodAccess getCall, EqualityTest nullCheck, ConditionNode conditionNode, ConditionNode successor
where
    threadLocalVar.getAnAccess() = getCall.getQualifier()
    and getCall.getMethod().getAnOverride*() instanceof GetMethod
    and nullCheck.getAnOperand() instanceof NullLiteral
    and DataFlow::localExprFlow(getCall, nullCheck.getAnOperand())
    and conditionNode.getCondition() = nullCheck
    and successor = conditionNode.getABranchSuccessor(nullCheck.polarity())
    and not exists (MethodAccess setCall |
        setCall.getMethod() instanceof SetMethod
        and setCall.getQualifier() = threadLocalVar.getAnAccess()
        and setCall.getBasicBlock() = successor
    )
    and not exists (MethodAccess removeCall |
        removeCall.getMethod() instanceof RemoveMethod
        and removeCall.getQualifier() = threadLocalVar.getAnAccess()
        and removeCall.getBasicBlock() = successor
    )
select threadLocalVar, nullCheck
