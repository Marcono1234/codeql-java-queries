/**
 * Finds expressions which seem to try rounding down a value `a` to the next smaller
 * multiple of `b`, but which seem to be incorrectly implemented.
 *
 * The correct expression is `a / b * b` (where `a` and `b` are integral numbers).
 * The following incorrect expressions are detected:
 * - `a / b` producing a floating point number; in that case `a / b * b` is most
 *   likely the same as `a` (except for some floating point precision loss),
 *   or possibly brackets are missing and it should have been `a / (b * b)`
 * - `a / b * a`; the `* a` seems incorrect and should probably be `* b`
 *
 * @id todo
 * @kind problem
 */

import java
import lib.VarAccess

predicate haveSameValue(Expr a, Expr b) {
  a.getType() = b.getType() and a.(Literal).getValue() = b.(Literal).getValue()
  or
  accessSameVarOfSameOwner(a, b)
}

from DivExpr div, Expr divisor, MulExpr mul, Expr mulOperand
where
  // Match `... / divisor * mulOperand`
  mul.getLeftOperand() = div and
  mulOperand = mul.getRightOperand() and
  div.getRightOperand() = divisor and
  (
    // Redundant division because result is floating point, e.g. `(a / 2.0) * 2` (= `a`, with some floating point precision loss)
    div.getType() instanceof FloatingPointType and
    haveSameValue(divisor, mulOperand)
    or
    // TODO: Maybe remove this case (also from documentation of query)? At least Variant Analysis did not find any case of this

    // Or accidental `(a / b) * a` when it should probably have been `(a / b) * b`
    haveSameValue(div.getLeftOperand(), mulOperand) and
    // Ignore if this calculates square of expression, e.g. `a / b * a / b`
    not exists(DivExpr rightDiv |
      rightDiv.getLeftOperand() = mul and
      haveSameValue(rightDiv.getRightOperand(), divisor)
    )
  )
select mul, "Performs incorrect rounding division"
