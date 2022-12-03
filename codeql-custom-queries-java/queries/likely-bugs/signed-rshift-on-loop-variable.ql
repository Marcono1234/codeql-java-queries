/**
 * Finds loops which check whether an integral variable has the value `0` or whether
 * certain bits are set or cleared, and which uses a signed right shift `>>` in the
 * loop to update the variable. This can lead to an endless loop when the variable
 * can be negative because in that case the `>>` operator keeps adding a `1` bit on
 * the left and the loop condition might therefore always be true.
 * 
 * @kind problem
 */

import java

from LoopStmt loop, Expr check, Variable var, Expr shift
where
    (
        // Checks for `!= 0`
        exists(NEExpr notZeroCheck | check = notZeroCheck |
            loop.getCondition() = notZeroCheck
            and (
                notZeroCheck.getAnOperand() = var.getAnAccess()
                or notZeroCheck.getAnOperand().(AssignRShiftExpr) = shift
            )
            and notZeroCheck.getAnOperand().(Literal).getValue() = "0"
        )
        // Or checks for `& x == 1` or `& x != 0`
        or exists(EqualityTest equalityCheck, AndBitwiseExpr bitAnd | check = equalityCheck |
            loop.getCondition() = equalityCheck
            and equalityCheck.getAnOperand() = bitAnd
            and if (equalityCheck.polarity() = true) then (
                equalityCheck.getAnOperand().(Literal).getValue() = "1"
            ) else (
                equalityCheck.getAnOperand().(Literal).getValue() = "0"
            )
            and (
                bitAnd.getAnOperand() = var.getAnAccess()
                or bitAnd.getAnOperand().(AssignRShiftExpr) = shift
            )
        )
    )
    and shift.getAnEnclosingStmt() = loop
    and (
        // `x = x >> ...`
        exists(AssignExpr assign |
            assign.getDest() = var.getAnAccess()
            and assign.getRhs() = shift
            and shift.(RShiftExpr).getLeftOperand() = var.getAnAccess()
            and assign.getAnEnclosingStmt() = loop
        )
        // Or `x >>= ...`
        or shift.(AssignRShiftExpr).getDest() = var.getAnAccess()
    )
select check, "Might result in endless loop due to $@", shift, "this signed right shift"
