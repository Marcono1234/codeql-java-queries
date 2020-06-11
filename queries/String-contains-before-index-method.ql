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
    and not exists (Assignment assignment, ControlFlowNode assignNode |
        assignment.getDest() = var.getAnAccess()
        and assignNode = assignment.getControlFlowNode()
        and assignNode.getAPredecessor*() = containsCall
        and assignNode.getASuccessor*() = indexCall
        /*
         * In a loop where the variable is re-assigned, the assignment is after
         * the call (first iteration) and before the call (subsequent iteration)
         * See also https://github.com/github/codeql/issues/3688
         *
         * There is already code duplication for contains and index (both use the
         * same string literal), so it is probably acceptable to refactor the code
         * and duplicate the index call instead
         *
         * Therefore only consider cases where the assignment only happens
         * before the call
         */
        and not assignNode.getAPredecessor*() = indexCall
    )
    and indexCall.getBasicBlock() = conditionNode.getATrueSuccessor()
    and containsCall.getArgument(0).(CompileTimeConstantExpr).getStringValue() = indexCall.getArgument(0).(CompileTimeConstantExpr).getStringValue()
select containsCall, indexCall
