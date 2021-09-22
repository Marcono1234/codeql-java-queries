/**
 * Finds bitwise shift expressions which could be replaced with a multiplication
 * or division to improve readability.
 */

import java
import lib.Expressions

/** Gets the corresponding multiplication factory, in case it is still easily readable */
int getReadableMultiplicationFactor(int shiftDistance) {
    shiftDistance = 1 and result = 2
    or shiftDistance = 2 and result = 4
    or shiftDistance = 3 and result = 8
}

class ShiftExpr extends Expr {
    int shiftDistance;
    boolean isLeftShift;

    ShiftExpr() {
        exists(IntegralLiteral i | shiftDistance = i.getIntValue() |
            isLeftShift = true
            and i = [
                this.(LShiftExpr).getRightOperand(),
                this.(AssignLShiftExpr).getRhs()
            ]
            or
            isLeftShift = false
            and i = [
                this.(RShiftExpr).getRightOperand(),
                this.(AssignRShiftExpr).getRhs()
                // Don't consider unsigned right shift because it is not equivalent to division
            ]
        )
    }

    int getShiftDistance() {
        result = shiftDistance
    }

    predicate isLeftShift() {
        isLeftShift = true
    }
}

from ShiftExpr shiftExpr, int factor, string alternativeOperator
where
    factor = getReadableMultiplicationFactor(shiftExpr.getShiftDistance())
    and if shiftExpr.isLeftShift() then alternativeOperator = "*"
    else alternativeOperator = "/"
    // And there is no other bitwise expression
    and not exists(BitwiseExpr_ otherBitwiseExpr |
        shiftExpr.getParent*() = otherBitwiseExpr.getParent*()
        and shiftExpr != otherBitwiseExpr
    )
    // Ignore cases where a value or multiple array elements are shifted with different distances
    and not exists(BlockStmt enclosingBlock, ShiftExpr otherShiftExpr |
        enclosingBlock = shiftExpr.getEnclosingStmt().getEnclosingStmt()
        and enclosingBlock = otherShiftExpr.getEnclosingStmt().getEnclosingStmt()
        // And other expression is of same type
        and shiftExpr.getKind() = otherShiftExpr.getKind()
        // And other expression also has integral literal as shift distance
        and exists(otherShiftExpr.getShiftDistance())
        and shiftExpr != otherShiftExpr
    )
select shiftExpr, "Could be replaced with `" + alternativeOperator + " " + factor +"`"
