/**
 * Finds equality tests (!=, ==) on loop counter variables.
 * This might allow an DOS attack or other exploitative behavior
 * if the initial counter value can be controlled externally
 * or if there is a bug in the incrementing / decrementing logic
 * allowing the counter to run past the end.
 *
 * A comparison expression (e.g. <, >=, ...) should be preferred.
 */

import java

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

predicate containsIncrOrDecr(ExprParent parent, Variable var) {
    exists (Expr incrOrDecrExpr | incrOrDecr(var, incrOrDecrExpr) |
        incrOrDecrExpr.getParent*() = parent
    )
}

predicate isEqTestOnCounterVar(EqualityTest eqTest, Variable var) {
    exists (ForStmt for |
        eqTest = for.getCondition()
        and (
            containsIncrOrDecr(for.getAnUpdate(), var)
            or containsIncrOrDecr(for.getStmt(), var)
        )
    )
    or exists (WhileStmt while |
        eqTest = while.getCondition()
        and containsIncrOrDecr(while.getStmt(), var)
    )
    or exists (DoStmt doWhile |
        eqTest = doWhile.getCondition()
        and containsIncrOrDecr(doWhile.getStmt(), var)
    )
}

from EqualityTest eqTest, Variable var
where
    var.getType() instanceof NumericType
    and var.getAnAccess().(RValue) = eqTest.getAnOperand()
    and isEqTestOnCounterVar(eqTest, var)
select eqTest
