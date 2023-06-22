/**
 * Finds bitwise shift expressions where the shift distance value is outside the normal
 * range. The bitwise shift operators only use the lowest 5 (for `int`) respectively
 * 6 (for `long`) bits of the shift distance, any higher set bits are ignored.
 * Because not everyone might be familiar with this behavior, relying on it should be
 * avoided because it might make maintaining the code more difficult.
 * 
 * See also [JLS 17 §15.19. Shift Operators](https://docs.oracle.com/javase/specs/jls/se17/html/jls-15.html#jls-15.19)
 * 
 * @kind problem
 */

// Has overlap with https://github.com/github/codeql/blob/main/java/ql/src/Likely%20Bugs/Arithmetic/LShiftLargerThanTypeWidth.ql

// TODO: Range analysis does not seem to be accurate, maybe using it wrongly

import java
import semmle.code.java.dataflow.RangeAnalysis

bindingset[isLong]
Reason getOutsideValidShiftRangeReason(Expr e, boolean isLong) {
    // Based on CodeQL's IntMultToLong.ql
    exists(int lower |
        bounded(e, any(ZeroBound zb), lower, false, result)
        and lower < 0
    )
    or exists(int upper |
        bounded(e, any(ZeroBound zb), upper, true, result)
    |
        isLong = true and upper > 63
        or isLong = false and upper > 31
    )
}

class ShiftExpr extends Expr {
    Expr shiftDistance;
    
    ShiftExpr() {
        shiftDistance = [
            this.(LeftShiftExpr).getRightOperand(),
            this.(AssignLeftShiftExpr).getRhs(),
            this.(RightShiftExpr).getRightOperand(),
            this.(AssignRightShiftExpr).getRhs(),
            this.(UnsignedRightShiftExpr).getRightOperand(),
            this.(AssignUnsignedRightShiftExpr).getRhs()
        ]
    }
    
    Expr getShiftDistanceExpr() {
        result = shiftDistance
    }
}

from ShiftExpr s, boolean isLong, Expr shiftDistance, Reason outsideRangeReason, string message, Top reported, string reportedString
where
    if s.getType().(IntegralType).hasName(["long", "Long"]) then isLong = true
    else isLong = false
    and shiftDistance = s.getShiftDistanceExpr()
    and outsideRangeReason = getOutsideValidShiftRangeReason(shiftDistance, isLong)
    and if outsideRangeReason instanceof CondReason then (
        message = "Shift distance is outside valid range due to $@ condition"
        and reported = outsideRangeReason.(CondReason).getCond()
        and reportedString = "this"
    )
    else (
        message = "$@ is outside valid range"
        and reported = shiftDistance
        and reportedString = "Shift distance"
    )
select s, message, reported, reportedString
