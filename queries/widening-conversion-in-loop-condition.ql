/**
 * Finds widening numeric conversion in loop conditions.
 * This can lead to infinite loops if the limit type is wider than
 * the counter type and has a value which the counter can never reach
 * because it overflows before reaching it.
 *
 * For example:
 * ```
 * public void skipExactly(long n) {
 *     int skippedTotal = 0;
 *     // If n > Integer.MAX_VALUE, skippedTotal will overflow and
 *     // loop runs forever
 *     while (skippedTotal < n) {
 *         skippedTotal += skip(n - skippedTotal);
 *     }
 * }
 * ```
 */

import java
import semmle.code.java.arithmetic.Overflow

class IntegralRead extends RValue {
    IntegralRead() {
        super.getType() instanceof NumType
        and super.getType() instanceof IntegralType
    }

    override
    NumType getType() {
        result = super.getType()
    }
}

bindingset[increment]
predicate incrOrDecr(Variable var, Expr expr, boolean increment) {
    exists (VarAccess varAccess | varAccess = var.getAnAccess() |
        if increment = true then (
            expr.(AssignAddExpr).getDest() = varAccess
            or expr.(PreIncExpr).getExpr() = varAccess
            or expr.(PostIncExpr).getExpr() = varAccess
        ) else (
            expr.(AssignSubExpr).getDest() = varAccess
            or expr.(PreDecExpr).getExpr() = varAccess
            or expr.(PostDecExpr).getExpr() = varAccess
        )
    )
}

bindingset[increment]
predicate containsIncrOrDecr(Stmt enclosing, Variable var, boolean increment) {
    exists (Expr incrOrDecrExpr | incrOrDecr(var, incrOrDecrExpr, increment) |
        incrOrDecrExpr.getEnclosingStmt().getEnclosingStmt+() = enclosing
    )
}

from LoopStmt loopStmt, ComparisonExpr comparison, IntegralRead opLesser, IntegralRead opGreater
where
    comparison = loopStmt.getCondition()
    and opLesser = comparison.getLesserOperand()
    and opGreater = comparison.getGreaterOperand()
    and (
        // Incrementing counter which is compared to wider limit
        (
            containsIncrOrDecr(loopStmt, opLesser.getVariable(), true)
            and opGreater.getType().widerThan(opLesser.getType())
            // Ignore limit constants because they are likely safe
            // (otherwise infinite loop would always happen)
            and not opGreater instanceof CompileTimeConstantExpr
        )
        // Decrementing counter which is compared to wider limit
        or (
            containsIncrOrDecr(loopStmt, opGreater.getVariable(), false)
            and opLesser.getType().widerThan(opGreater.getType())
            // Ignore limit constants because they are likely safe
            // (otherwise infinite loop would always happen)
            and not opLesser instanceof CompileTimeConstantExpr
        )
    )
select loopStmt
