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
import lib.Expressions

predicate containsIncrOrDecr(Stmt enclosing, Variable var) {
    exists (IncrOrDecrExpr incrOrDecrExpr |
        incrOrDecrExpr.getVarAccess().getVariable() = var
        and incrOrDecrExpr.getEnclosingStmt().getEnclosingStmt*() = enclosing
    )
}

predicate isEqTestOnCounterVar(EqualityTest eqTest, Variable var) {
    exists (LoopStmt loopStmt |
        eqTest = loopStmt.getCondition()
        and containsIncrOrDecr(loopStmt, var)
    )
}

from EqualityTest eqTest, Variable var
where
    var.getType() instanceof NumericType
    and var.getAnAccess().(RValue) = eqTest.getAnOperand()
    and isEqTestOnCounterVar(eqTest, var)
    // Reduce false positives by ignoring comparison with -1
    // Often an index search method (e.g. String.indexOf) is called within the loop
    // and then an increment expr is used to continue searching at a different index
    and not eqTest.getAnOperand().(CompileTimeConstantExpr).getIntValue() = -1
select eqTest, "Performs equality test on loop counter variable"
