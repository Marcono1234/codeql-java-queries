/**
 * Finds usage of `List.remove` followed by `List.add` to replace a list
 * element. It is most likely more performant to replace these two method calls
 * with `List.set` instead.
 */

import java
import lib.VarAccess

class TypeList extends Interface {
    TypeList() {
        hasQualifiedName("java.util", "List")
    }
}

class ListAddMethod extends Method {
    ListAddMethod() {
        getDeclaringType() instanceof TypeList
        and hasStringSignature("add(int, E)")
    }
}

class ListRemoveMethod extends Method {
    ListRemoveMethod() {
        getDeclaringType() instanceof TypeList
        and hasStringSignature("remove(int)")
    }
}

from MethodAccess removeCall, MethodAccess addCall
where
    removeCall.getMethod().getSourceDeclaration().getASourceOverriddenMethod*() instanceof ListRemoveMethod
    and addCall.getMethod().getSourceDeclaration().getASourceOverriddenMethod*() instanceof ListAddMethod
    and accessSameVarOfSameOwner(removeCall.getQualifier(), addCall.getQualifier())
    // Reduce false positives by only considering calls in same basic block
    and removeCall.getBasicBlock() = addCall.getBasicBlock()
    and removeCall.getControlFlowNode().getANormalSuccessor+() = addCall.getControlFlowNode()
    // And removal and addition use the same constant index or index variable
    and exists(Expr removeIndexArg, Expr addIndexArg |
        removeIndexArg = removeCall.getArgument(0)
        and addIndexArg = addCall.getArgument(0)
    |
        removeIndexArg.(CompileTimeConstantExpr).getIntValue() = addIndexArg.(CompileTimeConstantExpr).getIntValue()
        or accessSameVarOfSameOwner(removeIndexArg, addIndexArg)
    )
select removeCall, "Should replace this `remove` call followed by $@ `add` call with a call to `List.set`", addCall, "this"
