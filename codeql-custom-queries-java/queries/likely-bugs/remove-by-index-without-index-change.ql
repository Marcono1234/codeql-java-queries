/**
 * Finds loops which increment an index variable and perform a removal call with
 * that index as argument without adjusting the index variable. For example:
 * ```java
 * for (int i = 0; i < list.size(); i++) {
 *     if (matchesCondition(list.get(i))) {
 *         // Bad: Does not adjust index after removal, loop would continue at
 *         // element with original index i + 2
 *         list.remove(i);
 *     }
 * }
 * ```
 * 
 * When an element is removed all remaining elements are shifted. Therefore if the
 * index variable is not adjusted but instead incremented as usual, in the next
 * iteration the index variable would point to the element at the original index + 2
 * (due to element shifting) instead of + 1.
 * 
 * Note also that it might be less error-prone to use `List` methods such as
 * `removeAll`, `removeIf` or to use the iterator of the list and use its `remove()`
 * method (if supported).
 */

import java
import lib.Expressions
import lib.Loops

class IndexComparingExpr extends BinaryExpr {
    IndexComparingExpr() {
        this instanceof ComparisonExpr
        or this instanceof NEExpr
    }
}

class IndexRemovingMethod extends Method {
    IndexRemovingMethod() {
        (
            getDeclaringType().hasQualifiedName("java.util", "List")
            and hasStringSignature("remove(int)")
        )
        or (
            getDeclaringType() instanceof StringBuildingType
            and hasStringSignature("deleteCharAt(int)")
        )
    }
}

class IndexIncrementingLoop extends LoopStmt {
    LocalScopeVariable indexVar;
    
    IndexIncrementingLoop() {
        (
            indexVar = this.(ForStmt).getAnIterationVariable()
            or indexVar.getAnAccess() = this.getCondition().(IndexComparingExpr).getAnOperand()
        )
        and exists(IncrOrDecrExpr incrOrDecrExpr |
            incrOrDecrExpr.isIncrementing()
            and incrOrDecrExpr.getVarAccess().getVariable() = indexVar
            // Consider update in condition or body of loop
            and incrOrDecrExpr.getAnEnclosingStmt() = this
        )
    }
    
    LocalScopeVariable getIndexVar() {
        result = indexVar
    }
}

// Only consider index incrementing loops because for decrementing loops no index
// adjustements are needed
from IndexIncrementingLoop indexLoop, LocalScopeVariable indexVar, MethodAccess indexRemovingCall
where
    indexVar = indexLoop.getIndexVar()
    and indexRemovingCall.getAnEnclosingStmt() = indexLoop.getBody()
    and indexRemovingCall.getMethod().getSourceDeclaration().getASourceOverriddenMethod*() instanceof IndexRemovingMethod
    and indexRemovingCall.getArgument(0) = indexVar.getAnAccess()
    // And loop has or will be updating index variable; ignore cases where index update and
    // removal by index are two separate conditional branches
    and exists(LValue varUpdate |
        varUpdate.getVariable() = indexVar
        and varUpdate.getControlFlowNode() = [
            getASameIterationSuccessorNode(indexLoop, indexRemovingCall),
            getASameIterationPredecessorNode(indexLoop, indexRemovingCall)
        ]
    )
    // And index is not adjusted to account for removal
    and not exists(IncrOrDecrExpr decrExpr |
        not decrExpr.isIncrementing()
        and decrExpr.getVarAccess().getVariable() = indexVar
        // Removing call and update have same enclosing (block) statement
        and decrExpr.getEnclosingStmt().getEnclosingStmt() = indexRemovingCall.getEnclosingStmt().getEnclosingStmt()
        and decrExpr.getControlFlowNode() = indexRemovingCall.getControlFlowNode().getASuccessor+()
    )
select indexRemovingCall, "Removes element by index but does not adjust index variable afterwards"
