/**
 * Finds String index calls (e.g. `String.indexOf(String)`) which are preceded
 * by a call to `String.contains(CharSequence)`.
 * For better performance the `contains` call should be omitted and instead it
 * should be checked if the return value of the index method is -1, i.e. the
 * substring was not found.
 */

import java

class ContainsMethod extends Method {
    ContainsMethod() {
        getDeclaringType().hasQualifiedName("java.lang", "String")
        and hasStringSignature("contains(CharSequence)")
    }
}

class IndexMethod extends Method {
    IndexMethod() {
        getDeclaringType().hasQualifiedName("java.lang", "String")
        and getStringSignature() in [
            "indexOf(String)",
            "indexOf(String, int)",
            "lastIndexOf(String)",
            "lastIndexOf(String, int)"
        ]
    }
}

from ConditionNode conditionNode, Variable var, MethodAccess containsCall, MethodAccess indexCall
where
    containsCall.getMethod() instanceof ContainsMethod
    and containsCall.getQualifier() = var.getAnAccess()
    and conditionNode.getCondition() = containsCall
    and indexCall.getMethod() instanceof IndexMethod
    and indexCall.getQualifier() = var.getAnAccess()
    // Verify that there is no re-assignment to var between contains and index
    // Apparently causes some false negatives, see https://github.com/github/codeql/issues/3688
    and not exists (Assignment assignment |
        assignment.getDest() = var.getAnAccess()
        and assignment.getControlFlowNode().getAPredecessor*() = containsCall
        and assignment.getControlFlowNode().getASuccessor*() = indexCall
    )
    and indexCall.getBasicBlock() = conditionNode.getATrueSuccessor()
    and containsCall.getArgument(0).(CompileTimeConstantExpr).getStringValue() = indexCall.getArgument(0).(CompileTimeConstantExpr).getStringValue()
select containsCall, indexCall
