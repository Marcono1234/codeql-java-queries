/**
 * Finds comparison expressions and equality tests for which one operand is
 * a positive or negative 0 floating point literal, i.e. `-0.0f` or `+0.0d`.
 * These comparison expressions do not differentiate between negative and
 * positive 0 and therefore a 0 without any explicit sign should be preferred
 * to not irritate the reader. For example:
 * ```java
 * boolean isZero = d == +0.0 || d == -0.0;
 * 
 * // Is the same as
 * boolean isZero = d == 0.0;
 * ```
 * 
 * Use the static `compare` method or the `equals` method of the wrapper class
 * (e.g. `java.lang.Float`) methods to differentiate between those two types of 0.
 *
 * See also [JLS 17 §4.2.3. Floating-Point Types and Values](https://docs.oracle.com/javase/specs/jls/se17/html/jls-4.html#jls-4.2.3).
 * 
 * @kind problem
 */

import java
import lib.Literals

class ZeroFloatingPointLiteral extends FloatingPointLiteral_ {
    ZeroFloatingPointLiteral() {
        getValue().toFloat() = 0
    }
}

class SignedZero extends UnaryExpr {
    SignedZero() {
        (this instanceof MinusExpr or this instanceof PlusExpr)
        and getExpr() instanceof ZeroFloatingPointLiteral
    }
}

from BinaryExpr expr
where
    (
        expr instanceof ComparisonExpr
        or expr instanceof EqualityTest
    )
    and (
        expr.getAnOperand() instanceof SignedZero
        // Or reading variable whose constant value is -0.0 or +0.0
        or expr.getAnOperand().(CompileTimeConstantExpr).(RValue).getVariable().getInitializer() instanceof SignedZero
    )
select expr, "Comparison with -0.0 is same as comparison with +0.0"
