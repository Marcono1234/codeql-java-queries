/**
 * Finds conditional operators (`... ? ... : ...`) which check whether the value of
 * a variable is `null` and in that case have `null` as result and otherwise have
 * the variable as result. For example: `x == null ? null : x`.
 * 
 * Such code is redundant because it is equivalent to directly accessing the variable
 * without performing any `null` check. If the intention is to highlight that the
 * variable might be `null`, then it might be better to use annotations such as
 * `@Nullable` for this.
 */

import java
import lib.VarAccess

from ConditionalExpr condExpr, EqualityTest nullCheck, boolean isNull
where
    condExpr.getCondition() = nullCheck
    and nullCheck.getAnOperand() instanceof NullLiteral
    and isNull = nullCheck.polarity()
    and condExpr.getBranchExpr(isNull) instanceof NullLiteral
    // And other branch has variable as result
    and accessSameVarOfSameOwner(nullCheck.getAnOperand(), condExpr.getBranchExpr(isNull.booleanNot()))
select condExpr, "Redundant null check; could directly use variable"
