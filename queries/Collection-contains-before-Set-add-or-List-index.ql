/**
 * Finds calls to `java.util.Set.add(E)` or to the `java.util.List` index methods
 * (e.g. `List.indexOf(Object)`) which are only performed conditionally after a
 * `contains(Object)` call, e.g.:
 * ```
 * if (!set.contains("a")) {
 *     set.add("a");
 * }
 * ```
 * ```
 * if (list.contains("a")) {
 *     int i = list.indexOf("a");
 *     ...
 * }
 * ```
 * In both cases the call to `contains` is not necessary and performance can be
 * increased by omitting it and instead evaluating the return value of `Set.add`
 * (which returns `false` if the element was already contained) or the List
 * index methods (which return -1 if the element is not contained).
 */

import java

class ContainsMethod extends Method {
    ContainsMethod() {
        getDeclaringType().getErasure().(RefType).hasQualifiedName("java.util", "Collection")
        and hasStringSignature("contains(Object)")
    }
}

class SetAddMethod extends Method {
    SetAddMethod() {
        getDeclaringType().getErasure().(RefType).hasQualifiedName("java.util", "Set")
        // Checking string signature does not work reliably because type of parameter is
        // type parameter E, so check name and number of parameters instead
        and hasName("add")
        and getNumberOfParameters() = 1
    }
}

class ListIndexMethod extends Method {
    ListIndexMethod() {
        getDeclaringType().getErasure().(RefType).hasQualifiedName("java.util", "List")
        and getStringSignature() in ["indexOf(Object)", "lastIndexOf(Object)"]
    }
}

predicate areSameArguments(Expr a, Expr b) {
    // Same literal
    (
        a.getType() = b.getType()
        and a.(Literal).getValue() = b.(Literal).getValue()
    )
    // Or same variable read
    or exists (Variable var |
        a = var.getAnAccess()
        and b = var.getAnAccess()
        // Make sure there is no variable change between the usage of the two arguments
        // In theory method call on var could change value and change result of equality
        // check, however checking for that here might cause too many false negatives
        and not exists (LValue varWrite | varWrite.getVariable() = var |
            a.getControlFlowNode().getASuccessor+() = varWrite
            and b.getControlFlowNode().getAPredecessor+() = varWrite
        )
    )
}

from Variable var, ConditionNode condition, MethodAccess containsCall, MethodAccess addOrIndexCall
where
    containsCall.getQualifier() = var.getAnAccess()
    and containsCall.getMethod().getAnOverride*() instanceof ContainsMethod
    and condition.getCondition() = containsCall
    and addOrIndexCall.getQualifier() = var.getAnAccess()
    and areSameArguments(containsCall.getArgument(0), addOrIndexCall.getArgument(0))
    and (
        (
            addOrIndexCall.getMethod().getAnOverride*() instanceof SetAddMethod
            // Performs contains check and only if not contained adds element
            // Caller could just call `add` instead and check for return value `true`
            and condition.getAFalseSuccessor+() = addOrIndexCall.getBasicBlock()
            // Make sure that `add` call does not happen in catch or similar
            and condition.getANormalSuccessor+() = addOrIndexCall.getBasicBlock()
            // Make sure that `add` happens unconditionally, i.e. there is not another ConditionNode in between
            and not exists (ConditionNode otherCondition |
                otherCondition.getAPredecessor+() = condition
                and otherCondition.getABranchSuccessor(_).getASuccessor*() = addOrIndexCall.getBasicBlock()
            )
        )
        // TODO: Not tested yet
        or (
            addOrIndexCall.getMethod().getAnOverride*() instanceof ListIndexMethod
            // Performs contains check and only if contained tries to get index
            // Caller could just call index method and check for return value != -1
            and condition.getATrueSuccessor+() = addOrIndexCall
        )
    )
    // Make sure there is no other usage of the collection between the calls
    and not exists (VarAccess varAccess | varAccess = var.getAnAccess() |
        varAccess != addOrIndexCall.getQualifier()
        and containsCall.getControlFlowNode().getASuccessor+() = varAccess
        and addOrIndexCall.getControlFlowNode().getAPredecessor+() = varAccess
    )
select containsCall, addOrIndexCall
