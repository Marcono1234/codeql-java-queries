/**
 * Finds calls to `String.toCharArray()` which can be avoided. `toCharArray()`
 * creates a new char array. For performance reasons it is therefore better to
 * directly use the methods of String instead of operating on the array.
 * E.g.:
 * ```
 * // Inefficient, especially for large strings; should instead use
 * // `s.length() == 1 && s.charAt(0) == 'a'`
 * char[] chars = s.toCharArray();
 * if (chars.length == 1 && chars[0] == 'a') {
 *     ...
 * }
 * ```
 */

import java
import semmle.code.java.dataflow.DataFlow

class ToCharArrayMethod extends Method {
    ToCharArrayMethod() {
        getDeclaringType() instanceof TypeString
        and hasStringSignature("toCharArray()")
    }
}

class LeakingExpr extends Expr {
    LeakingExpr() {
        // Leaks by passing it as argument to call
        any(Call c).getAnArgument() = this
        // Leaks by assigning to field
        or any(FieldWrite w).getRhs() = this
        // Leaks by storing in array
        or exists(AssignExpr assign |
            assign.getRhs() = this
            and assign.getDest() instanceof ArrayAccess
        )
        // Leaks by putting in new array
        or any(ArrayInit a).getAnInit() = this
        // Leaks by returning
        or any(ReturnStmt r).getResult() = this
        // Leaks by being captured, e.g. in lambda, inner class, ...
        or exists(LocalScopeVariable var |
            this = var.getAnAssignedValue()
            and var.getAnAccess().getEnclosingCallable() != getEnclosingCallable()
        )
    }
}

predicate isLeaked(Expr leaked) {
    DataFlow::localFlow(DataFlow::exprNode(leaked), DataFlow::exprNode(any(LeakingExpr e)))
}

predicate incrOrDecr(Variable var, Expr expr) {
    exists (VarAccess varAccess | varAccess = var.getAnAccess() |
        expr.(AssignAddExpr).getDest() = varAccess
        or expr.(AssignSubExpr).getDest() = varAccess
        or expr.(PreIncExpr).getExpr() = varAccess
        or expr.(PostIncExpr).getExpr() = varAccess
        or expr.(PreDecExpr).getExpr() = varAccess
        or expr.(PostDecExpr).getExpr() = varAccess
    )
}

predicate containsIncrOrDecr(Stmt enclosing, Variable var) {
    exists (Expr incrOrDecrExpr | incrOrDecr(var, incrOrDecrExpr) |
        incrOrDecrExpr.getAnEnclosingStmt() = enclosing
    )
}

// Note: Yields some false positives when accessed is in loop and array index is
//       random based and not influenced by counter variable

from MethodAccess toCharArrayCall
where
    toCharArrayCall.getMethod() instanceof ToCharArrayMethod
    // Result is not leaked
    and not isLeaked(toCharArrayCall)
    // Ignore if char array is used in loop; then it might be more efficient than calling
    // String methods in every iteration or using Stream
    and not exists(EnhancedForStmt forStmt |
        DataFlow::localFlow(DataFlow::exprNode(toCharArrayCall), DataFlow::exprNode(forStmt.getExpr()))
    )
    and not exists(LoopStmt loop, Variable counterVar, ArrayAccess arrayAccess |
        containsIncrOrDecr(loop, counterVar)
        and counterVar.getAnAccess().getParent*() = arrayAccess.getIndexExpr()
        and DataFlow::localFlow(DataFlow::exprNode(toCharArrayCall), DataFlow::exprNode(arrayAccess.getArray()))
    )
select toCharArrayCall, "Can avoid calling String.toCharArray()"
