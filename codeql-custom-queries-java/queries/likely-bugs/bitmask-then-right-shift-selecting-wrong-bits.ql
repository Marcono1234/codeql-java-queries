/**
 * Finds expressions which first apply a bitmask (by using `&`) and afterwards shift the
 * result to the right where either bitmask or shift distance indicate that the result
 * is potentionally not what was intended to be selected.
 */

import java
import lib.Strings

// TODO: Ideally would support this for `long` bitmasks too, but CodeQL currently does not have 64bit integer type
from AndBitwiseExpr andExpr, BinaryExpr shiftExpr, int bitmask, int firstBitmaskBitIndex, int shiftDistance, string message
where
    shiftExpr.getLeftOperand() = andExpr
    and bitmask = andExpr.getAnOperand().(CompileTimeConstantExpr).getIntValue()
    and (shiftExpr instanceof RShiftExpr or shiftExpr instanceof URShiftExpr)
    and shiftDistance = shiftExpr.getRightOperand().(CompileTimeConstantExpr).getIntValue()
    and firstBitmaskBitIndex = [0..31]
    and bitmask.bitAnd(1.bitShiftLeft(firstBitmaskBitIndex)) != 0
    // And there is not another bit at a lower index set
    and not exists(int otherBitIndex |
        otherBitIndex = [0..firstBitmaskBitIndex - 1]
        and bitmask.bitAnd(1.bitShiftLeft(otherBitIndex)) != 0
    )
    and (
        (
            firstBitmaskBitIndex > shiftDistance
            and message = "Result includes " + (firstBitmaskBitIndex - shiftDistance) + " low 0 bits"
            // Ignore if result is combined with `|`, zero bits might then be intended
            and not any(OrBitwiseExpr orExpr).getAnOperand() = shiftExpr
        )
        or (
            // Part of bitmask is shifted away
            firstBitmaskBitIndex < shiftDistance
            // Ignore false positives when not shifting multiple of 4, e.g. `(x & 0xF) >> 2`
            and shiftDistance.bitAnd(3) = 0 // Is equivalent to x % 4 == 0
            and message = "Bits selected by bitmask are shifted away; bitmask could be simplified to: 0x" + unsignedToHex(bitmask.bitAnd((1.bitShiftLeft(shiftDistance) - 1).bitNot()))
        )
    )
select andExpr, message
