/**
 * Finds expressions which first apply a bitmask (by using `&`) and afterwards shift the
 * result to the right. Compared to performing this in reverse order, that is, first shifting
 * to the right and then applying the bitmask, this has the following disadvantages:
 * - The bitmask position has to match the shift distance; if performed in reverse order
 *   the bitmask always starts at the lowest bit, which is less error-prone
 * - If a signed right shift is used (`>>`) and the bitmask includes the most significant
 *   bit representing the sign, the result can become incorrect because the signed shift operator
 *   extends the sign bit to all shifted bits; if performed in reverse order this is not
 *   an issue because the bitmask will then not include the sign bit
 */

// Note: In some cases it might be more readable to first apply bitmask and then perform shift

import java

from AndBitwiseExpr andExpr, BinaryExpr shiftExpr
where
    shiftExpr.getLeftOperand() = andExpr
    and andExpr.getAnOperand() instanceof CompileTimeConstantExpr
    and (shiftExpr instanceof RightShiftExpr or shiftExpr instanceof UnsignedRightShiftExpr)
    // Only consider if shift distance is constant
    and shiftExpr.getRightOperand() instanceof CompileTimeConstantExpr
select andExpr, "Should first perform shift and then apply bitmask"
