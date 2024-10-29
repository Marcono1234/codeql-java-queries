/**
 * Finds bit mask checks which seem to always be `false` because not all checked
 * bits can actually be set.
 *
 * Similar to SpotBugs':
 * - [`BIT_AND`](https://spotbugs.readthedocs.io/en/latest/bugDescriptions.html#bit-incompatible-bit-masks-bit-and)
 * - [`BIT_IOR`](https://spotbugs.readthedocs.io/en/latest/bugDescriptions.html#bit-incompatible-bit-masks-bit-ior)
 *
 * @id TODO
 * @kind problem
 */

// TODO: Might need further refinement

import java

// Separate predicate which is not directly used by `where` clause of this query so that any equality tests which
// directly compare mismatching constants (e.g. `1 == 2`, which might occur in unit tests or for debug flags which
// can be enabled by changing the code), are not reported as 'bit checks' by this query
int getPossibleBitsOrVar(Expr e) {
  result = getPossibleBits(e)
  or
  result = e.(CompileTimeConstantExpr).getIntValue()
  or
  // All bits are possible when reading non-constant var
  e instanceof RValue and not e instanceof CompileTimeConstantExpr and result = -1
}

predicate isPowerOf2(int i) {
  i =
    [
      1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072,
      262144, 524288, 1048576, 2097152, 4194304, 8388608, 16777216, 33554432, 67108864, 134217728,
      268435456, 536870912, 1073741824
    ]
}

/**
 * For an expression, gets its int value where all bits which at runtime _might_ be set have the
 * value 1. And all bits which are definitely not set have the value 0.
 */
int getPossibleBits(Expr e) {
  /*
   * TODO: For bitwise 'not', applying `bitNot()` here can cause false positives because it is only known
   * here that 0 bits are guaranteed to not be set, but 1 bits might or might not be set. So using `bitNot()`
   * will turn those 1 bits into 'definitely not set', which is incorrect.
   * Would be more correct to either use -1 (all bits possible) as result, or instead additionally need to
   * track which bits are guaranteed to be 1, and only invert those (might also be useful for XOR).
   */

  result = getPossibleBitsOrVar(e.(BitNotExpr).getExpr()).bitNot()
  or
  exists(OrBitwiseExpr orExpr | orExpr = e |
    result =
      getPossibleBitsOrVar(orExpr.getLeftOperand())
          .bitOr(getPossibleBitsOrVar(orExpr.getRightOperand()))
  )
  or
  // Treat XOR like OR: It is only known here that 0 bits are guaranteed to not be set, but 1 bits might or
  // might not be set. So using `bitXor` could lead to incorrect results.
  exists(XorBitwiseExpr xorExpr | xorExpr = e |
    result =
      getPossibleBitsOrVar(xorExpr.getLeftOperand())
          .bitOr(getPossibleBitsOrVar(xorExpr.getRightOperand()))
  )
  or
  exists(AndBitwiseExpr andExpr | andExpr = e |
    result =
      getPossibleBitsOrVar(andExpr.getLeftOperand())
          .bitAnd(getPossibleBitsOrVar(andExpr.getRightOperand()))
  )
  or
  exists(LeftShiftExpr shiftExpr | shiftExpr = e |
    result =
      getPossibleBitsOrVar(shiftExpr.getLeftOperand())
          .bitShiftLeft(shiftExpr.getRightOperand().(CompileTimeConstantExpr).getIntValue())
  )
  or
  exists(UnsignedRightShiftExpr shiftExpr | shiftExpr = e |
    result =
      getPossibleBitsOrVar(shiftExpr.getLeftOperand())
          .bitShiftRight(shiftExpr.getRightOperand().(CompileTimeConstantExpr).getIntValue())
  )
  or
  exists(RightShiftExpr shiftExpr | shiftExpr = e |
    result =
      getPossibleBitsOrVar(shiftExpr.getLeftOperand())
          .bitShiftRightSigned(shiftExpr.getRightOperand().(CompileTimeConstantExpr).getIntValue())
  )
  or
  exists(DivExpr divExpr, int divisor | divExpr = e |
    divisor = divExpr.getRightOperand().(CompileTimeConstantExpr).getIntValue() and
    // If power of 2, then this acts like a bit shift and can be performed without knowing exact value
    isPowerOf2(divisor) and
    result = getPossibleBitsOrVar(divExpr.getLeftOperand()) / divisor
  )
  or
  exists(MulExpr mulExpr, Expr valueOp, CompileTimeConstantExpr multiplierOp, int multiplier |
    mulExpr = e and
    valueOp = mulExpr.getAnOperand() and
    multiplierOp = mulExpr.getAnOperand() and
    valueOp != multiplierOp
  |
    multiplier = multiplierOp.getIntValue() and
    // If power of 2, then this acts like a bit shift and can be performed without knowing exact value
    isPowerOf2(multiplier) and
    result = getPossibleBitsOrVar(valueOp) * multiplier
  )
}

from EQExpr eqExpr, CompileTimeConstantExpr checkedExpr, int checkedValue, Expr bitExpr
where
  checkedExpr = eqExpr.getAnOperand() and
  bitExpr = eqExpr.getAnOperand() and
  checkedExpr != bitExpr and
  checkedValue = checkedExpr.getIntValue() and
  checkedValue != 0 and
  // And not all checked bits can actually be set
  checkedValue.bitAnd(getPossibleBits(bitExpr)) != checkedValue
select eqExpr, "Will never succeed because bit value will never match"
