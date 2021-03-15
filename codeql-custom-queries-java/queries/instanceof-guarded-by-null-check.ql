/**
 * Finds `instanceof` expressions which are guarded by a `null` check for
 * the same variable, e.g.:
 * ```
 * if (obj != null && obj instanceof String) {
 *     ...
 * }
 * ```
 *
 * `instanceof` also returns `false` if the expression is null, so guarding
 * it with an explicit null check is not necessary.
 *
 * See https://docs.oracle.com/javase/specs/jls/se11/html/jls-15.html#jls-15.20.2
 */

import java

from Variable var, AndLogicalExpr andExpr, NEExpr nullCheck, InstanceOfExpr instanceOfExpr
where
    nullCheck = andExpr.getLeftOperand()
    and instanceOfExpr = andExpr.getRightOperand()
    and nullCheck.getAnOperand() = var.getAnAccess()
    and nullCheck.getAnOperand() instanceof NullLiteral
    and instanceOfExpr.getExpr() = var.getAnAccess()
select nullCheck, instanceOfExpr
