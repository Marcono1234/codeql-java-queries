/**
 * Finds `equals(Object)` implementations which compare floating point values
 * using `==` or `!=`. If the floating point values can be NaN, this could
 * result in `this.equals(this)` being false (depending on how it is implemented),
 * which violates the equals contract. Or it could cause unexpected behavior
 * for objects which should be considered equal.
 *
 * To solve this, one could check `Float.floatToIntBits(f) == Float.floatToIntBits(other.f)`
 */

import java

predicate isInEqualsMethod(Expr e) {
    exists(Method m |
        m.hasStringSignature("equals(Object)")
        and e.getEnclosingCallable() = m
    )
}

from EqualityTest eq, FieldAccess leftFa, FieldAccess rightFa
where
    isInEqualsMethod(eq)
    and eq.getLeftOperand() = leftFa
    and eq.getRightOperand() = rightFa
    and leftFa.getField() = rightFa.getField()
    and leftFa.getField().getType() instanceof FloatingPointType
select eq
