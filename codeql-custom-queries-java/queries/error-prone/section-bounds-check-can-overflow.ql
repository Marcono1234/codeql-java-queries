/**
 * Finds section (i.e. start index and section length) bounds checks
 * which can overflow, e.g.:
 * ```
 * String getSubString(int off, int len) {
 *     if (off < 0 || len < 0) {
 *         throw new IllegalArgumentException();
 *     }
 *     // Will overflow if `off + len > Integer.MAX_VALUE`
 *     // In that case the check would erroneously consider the arguments valid
 *     if (off + len > size()) {
 *         throw new IllegalArgumentException();
 *     }
 *     ...
 * }
 * ```
 *
 * If it is known (or has been verified before) that the variables
 * cannot be negative, then a subtraction should be performed instead,
 * which cannot overflow. E.g.:
 * ```
 * // Cannot overflow (assuming none of the values can be < 0)
 * if (off > size() - len) {
 *     throw new IllegalArgumentException();
 * }
 * ```
 */
 
// TODO: Might have to reduce false positives

import java
import semmle.code.java.arithmetic.Overflow
import lib.Expressions

// Only consider int and long because smaller types (e.g. byte) would
// have widening conversion on addition and therefore cannot overflow
class IntOrLong extends Type {
    IntOrLong() {
        this.(PrimitiveType).hasName(["int", "long"])
        or this.(BoxedType).getPrimitiveType().hasName(["int", "long"])
    }
}

class IntegralVarAccess extends VarAccess {
    IntegralVarAccess() {
        getType() instanceof IntOrLong
    }
}

// Also covers accessing `length` field of array
class IntegralVarAccessMethodCallOrLiteral extends Expr {
    IntegralVarAccessMethodCallOrLiteral() {
        (
            this instanceof VarAccess
            or this.(IntegralLiteral).isPositive()
            or this instanceof MethodAccess
        )
        and getType() instanceof IntOrLong
    }
}

predicate isFixedValue(Expr e) {
    e instanceof Literal
    or exists (Field f | f = e.(FieldRead).getField() |
        f.isStatic()
    )
    // Local variable whose value does not change
    // TODO: Verify that this works
    or exists (LocalVariableDecl var | var = e.(VarAccess).getVariable() |
        exists (var.getInitializer())
        and not exists (LValue write |
            write.getVariable() = var
            and write != var.getDeclExpr().getTypeAccess()
        )
    )
}

predicate performsOneOpWideningConversion(Expr a, Expr b) {
    // Check if fixed value has larger type than other expr
    // E.g. `1L + size` (with `size` being `int`)
    (
        isFixedValue(a)
        and a.getType().(NumType).widerThan(b.getType())
    )
    // Reverse arguments
    or performsOneOpWideningConversion(b, a)
}

from ComparisonExpr boundsCheck, AddExpr add, Expr addLeft, Expr addRight, IntegralVarAccessMethodCallOrLiteral lengthRead
where
    add = boundsCheck.getAnOperand()
    and lengthRead = boundsCheck.getAnOperand()
    and add != lengthRead
    and addLeft = add.getLeftOperand()
    and addRight = add.getRightOperand()
    // Only one of the operands must be a literal or method call
    and (
        (addLeft instanceof IntegralVarAccessMethodCallOrLiteral and addRight instanceof IntegralVarAccess)
        or (addLeft instanceof IntegralVarAccess and addRight instanceof IntegralVarAccessMethodCallOrLiteral)
    )
    // Ignore if addition performs widening conversion, cannot
    // overflow then
    and not performsOneOpWideningConversion(addLeft, addRight)
select boundsCheck, "Bounds check can overflow"
