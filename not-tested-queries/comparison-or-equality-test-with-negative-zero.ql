/**
 * Finds comparison expressions and equality tests for which one operand is
 * a negative 0 floating point literal, i.e. `-0.0f` or `-0.0d`.
 * These expressions do not differentiate between negative and positive 0 and
 * therefore positive 0 should be preferred to not irritate the reader.
 * Use the wrapper class (e.g. `java.lang.Float`) methods to differentiate
 * between those two types of 0.
 *
 * See also https://docs.oracle.com/javase/specs/jls/se14/html/jls-4.html#jls-4.2.3
 */

import java

class ZeroFloatingPointLiteral extends Literal {
    ZeroFloatingPointLiteral() {
        (
            this instanceof FloatingPointLiteral
            or this instanceof DoubleLiteral
        )
        and getValue().toFloat() = 0
    }
}

class MinusZeroExpr extends MinusExpr {
    MinusZeroExpr() {
        getExpr() instanceof ZeroFloatingPointLiteral
    }
}

from BinaryExpr expr
where
    (
        expr instanceof ComparisonExpr
        or expr instanceof EqualityTest
    )
    and (
        expr.getAnOperand() instanceof MinusZeroExpr
        // Or reading variable whose constant value is -0.0
        or expr.getAnOperand().(CompileTimeConstantExpr).(RValue).getVariable().getInitializer() instanceof MinusZeroExpr
    )
select expr
