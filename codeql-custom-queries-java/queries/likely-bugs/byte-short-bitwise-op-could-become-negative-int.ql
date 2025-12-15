/**
 * Finds bitwise operations which could unintentionally convert a `byte` or `short` to
 * a negative `int`. Bitwise operations perform implicit widening conversion to `int`
 * and preserve the sign of the original value. Therefore if the `byte` or `short` is
 * negative it could turn the result negative as well, even though the `byte` or `short`
 * was intended to be treated as unsigned.
 *
 * To avoid this, explicitly treat the value as unsigned and convert it to `int` before
 * performing other bitwise operations by doing `& 0xFF` (for byte) respectively `& 0xFFFF`
 * (for short).
 *
 * For example, consider this code snippet which is supposed to read a 16-bit integer:
 * ```java
 * // BAD: Does not treat bytes as unsigned
 * int i = bytes[0] | bytes[1] << 8;
 * ```
 * If one of the bytes is > 127, then the complete result erroneously becomes negative.
 *
 * To solve this, treat the bytes as unsigned using `& 0xFF`:
 * ```java
 * int i = (bytes[0] & 0xFF) | ((bytes[1] & 0xFF) << 8);
 * ```
 *
 * @kind problem
 * @id TODO
 */

// TODO: Maybe also consider `int` being ORed with `long`?

import java

class SignedSmallerThanIntType extends Type {
  SignedSmallerThanIntType() { unbox(this).hasName(["byte", "short"]) }
}

PrimitiveType unbox(Type t) { result = t or result = t.(BoxedType).getPrimitiveType() }

class SignPreservingShiftExpr extends BinaryExpr {
  SignPreservingShiftExpr() {
    this instanceof RightShiftExpr
    or
    this instanceof UnsignedRightShiftExpr
    or
    this instanceof LeftShiftExpr and
    // And does not explicitly overwrite sign bit by shifting value into it
    not this.getRightOperand().(CompileTimeConstantExpr).getIntValue() >= 24
  }
}

from BinaryExpr bitwiseExpr, Expr bitwiseOperand
where
  bitwiseOperand.getType() instanceof SignedSmallerThanIntType and
  // Only cover the bitwise operations where the implicit sign conversion has an effect (and is likely undesired)
  (
    bitwiseExpr.(OrBitwiseExpr).getAnOperand() = bitwiseOperand or
    bitwiseExpr.(SignPreservingShiftExpr).getLeftOperand() = bitwiseOperand
  ) and
  // Ignore if parent discards implicit sign bits again
  not bitwiseExpr.getParent() instanceof AndBitwiseExpr and
  not exists(CastExpr castExpr, int targetByteSize, int opByteSize |
    castExpr = bitwiseExpr.getParent+() and
    targetByteSize = castExpr.getType().(IntegralType).getByteSize() and
    opByteSize = bitwiseOperand.getType().(IntegralType).getByteSize()
  |
    // Target type is <= op type, e.g. casting `short` to `byte`
    targetByteSize <= opByteSize
    or
    // Target type is potentially larger, but op was shifted explicitly into sign bit
    bitwiseExpr.(LeftShiftExpr).getRightOperand().(CompileTimeConstantExpr).getIntValue() / 8 >=
      targetByteSize - opByteSize
  ) and
  // Ignore if op is a constant expr, then the bitwise operation is likely intentional
  not bitwiseOperand instanceof CompileTimeConstantExpr and
  // Ignore patterns like `a | CONST == CONST` (or !=); for example Guava uses that to check for all
  // bits being 0 ignoring those matched by the bitmask
  // Explicitly require a CompileTimeConstantExpr here; for example Netty has multiple checks like
  // `a[0] | (a[1] << 8) == CONST` where non-const values are ORed; those don't actually seem safe
  not exists(CompileTimeConstantExpr maskOp |
    maskOp = bitwiseExpr.(OrBitwiseExpr).getAnOperand() and
    maskOp != bitwiseOperand and
    bitwiseExpr.getParent() instanceof EqualityTest
  ) and
  // Ignore patterns like `a >> ... == CONST` (or !=)
  not exists(EqualityTest eqTest |
    eqTest.getAnOperand() instanceof CompileTimeConstantExpr and
    bitwiseExpr = eqTest.getAnOperand() and
    (
      bitwiseExpr instanceof RightShiftExpr or
      bitwiseExpr instanceof UnsignedRightShiftExpr
    )
  )
select bitwiseExpr, "Implicitly converts $@ to a signed int", bitwiseOperand, "this expr"
