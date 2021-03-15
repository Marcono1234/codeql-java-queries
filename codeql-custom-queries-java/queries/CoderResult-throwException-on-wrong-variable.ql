/**
 * Finds calls to `CoderResult.throwException()` preceded by a `CoderResult`
 * error check call (e.g. `CoderResult.isError()`) performed on a different
 * variable; this might indicate that variables were interchanged.
 * E.g.:
 * ```
 * CoderResult result = ...;
 * ...
 * CoderResult result2 = ...;
 * if (result2.isError()) {
 *     // Called on the wrong variable; `result2` was checked
 *     result.throwException();
 * }
 * ```
 */

import java

class TypeCoderResult extends Class {
    TypeCoderResult() {
        hasQualifiedName("java.nio.charset", "CoderResult")
    }
}

class CoderResultMethod extends Method {
    CoderResultMethod() {
        getDeclaringType() instanceof TypeCoderResult
    }
}

abstract class CoderResultErrorCheckingMethod extends CoderResultMethod {
}

class IsErrorMethod extends CoderResultErrorCheckingMethod {
    IsErrorMethod() {
        hasStringSignature("isError()")
    }
}

class IsMalformedMethod extends CoderResultErrorCheckingMethod {
    IsMalformedMethod() {
        hasStringSignature("isMalformed()")
    }
}

class IsUnmappableMethod extends CoderResultErrorCheckingMethod {
    IsUnmappableMethod() {
        hasStringSignature("isUnmappable()")
    }
}

class ThrowExceptionMethod extends CoderResultMethod {
    ThrowExceptionMethod() {
        hasStringSignature("throwException()")
    }
}

abstract class CoderResultNoErrorCheckingMethod extends CoderResultMethod {
}

class IsOverflowMethod extends CoderResultNoErrorCheckingMethod {
    IsOverflowMethod() {
        hasStringSignature("isOverflow()")
    }
}

class IsUnderflowMethod extends CoderResultNoErrorCheckingMethod {
    IsUnderflowMethod() {
        hasStringSignature("isUnderflow()")
    }
}

private predicate areCloseTogether(Expr first, Expr second) {
    second.getLocation().getStartLine() - first.getLocation().getEndLine() < 5
}

from MethodAccess coderResultCheck, VarAccess resultCheckVarRead, ConditionNode conditionNode, boolean branch,
    MethodAccess throwExceptionCall, VarAccess throwVarRead
where
    coderResultCheck.getQualifier() = resultCheckVarRead
    and conditionNode.getCondition() = coderResultCheck
    and throwExceptionCall.getQualifier() = throwVarRead
    and exists(CoderResultMethod m | m = coderResultCheck.getMethod() |
        m instanceof CoderResultNoErrorCheckingMethod and branch = false
        or m instanceof CoderResultErrorCheckingMethod and branch = true
    )
    and throwExceptionCall.getMethod() instanceof ThrowExceptionMethod
    and conditionNode.getABranchSuccessor(branch).getASuccessor*() = throwExceptionCall.getControlFlowNode()
    // Make sure check and throw call are close together, otherwise they might be unrelated
    and areCloseTogether(coderResultCheck, throwExceptionCall)
    and resultCheckVarRead.getVariable() != throwVarRead.getVariable()
select throwVarRead, "Throws exception for $@, but $@ check is performed for $@",
    throwVarRead, throwVarRead.toString(), coderResultCheck, "this", resultCheckVarRead, resultCheckVarRead.toString()
