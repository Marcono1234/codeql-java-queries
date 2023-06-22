/**
 * Finds code which first shifts a value to the left and then shifts the result
 * to the right by the same distance. It might be clearer to replace this code
 * with usage of a bit mask, possibly written in binary or hexadecimal notation.
 * For example:
 * ```java
 * (x << 24) >>> 24
 * // Could be replaced with
 * x & 0xFF
 * // or
 * x & 0b1111_1111
 * ```
 */

import java

class IntOrLongLiteral extends Literal {
    IntOrLongLiteral() {
        this instanceof IntegerLiteral
        or this instanceof LongLiteral
    }

    int getIntValue() {
        result = getValue().toInt()
    }
}

// Only consider UnsignedRightShiftExpr; (signed) RightShiftExpr is sometimes used to 'extend' sign bit
from LeftShiftExpr leftShift, Expr leftShiftDistExpr, UnsignedRightShiftExpr rightShift, Expr rightShiftDistExpr
where
    leftShift = rightShift.getLeftOperand()
    and leftShiftDistExpr = leftShift.getRightOperand()
    and rightShiftDistExpr = rightShift.getRightOperand()
    and leftShiftDistExpr.(IntOrLongLiteral).getIntValue() = rightShiftDistExpr.(IntOrLongLiteral).getIntValue()
select leftShift, "Instead of first shifting left then shifting right, should use bit mask"
