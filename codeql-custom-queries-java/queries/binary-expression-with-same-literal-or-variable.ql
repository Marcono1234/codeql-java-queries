/**
 * Finds binary expressions where both operands represent a literal of
 * the same value or both operands read the same field or variable and
 * and usage of the operator of the expression does not make sense for
 * the same value, e.g.:
 * ```
 * // Due to precedence rules, `a / a` is evaluated first, which is always 1
 * int r = 1 + a / a;
 * ```
 *
 * This indicates that the code likely does not behave the way it was
 * originally designed.
 *
 * See also https://docs.oracle.com/javase/tutorial/java/nutsandbolts/operators.html
 */

import java

/**
 * Operator whose operands should not be the same.
 */
class NonSameOperandsOperator extends BinaryExpr {
    NonSameOperandsOperator() {
        this instanceof SubExpr
        or this instanceof DivExpr
        or this instanceof RemExpr
        or this instanceof OrLogicalExpr
        or this instanceof AndLogicalExpr
        or this instanceof BitwiseExpr // OR, XOR, AND
        or this instanceof ComparisonExpr
        or this instanceof EqualityTest
    }
}

predicate isSameVarRead(RValue a, RValue b) {
    a.getVariable() = b.getVariable()
    and 
    (
        // Both read same variable so checking one is enough
        a.getVariable() instanceof LocalScopeVariable
        or a.(FieldRead).getField().isStatic()
        or a.(FieldRead).isOwnFieldAccess() and b.(FieldRead).isOwnFieldAccess()
        or exists (RefType enclosing |
            a.(FieldRead).isEnclosingFieldAccess(enclosing)
            and b.(FieldRead).isEnclosingFieldAccess(enclosing)
        )
        or isSameVarRead(a.getQualifier(), b.getQualifier())
    )
}

from NonSameOperandsOperator expr
where
    isSameVarRead(expr.getLeftOperand(), expr.getRightOperand())
    or exists (Literal left, Literal right | left = expr.getLeftOperand() and right = expr.getRightOperand() |
        // Make sure literals have same kind, otherwise "1" would be same as 1
        // (though that is not possible for subtraction expression)
        left.getKind() = right.getKind()
        and left.getValue() = right.getValue()
    )
select expr
