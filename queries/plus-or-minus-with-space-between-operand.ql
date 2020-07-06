/**
 * Finds unary plus or minus expressions which have a space between
 * the operator and the operand, e.g.:
 * ```
 * int result =
 *    a * b
 *    // Here inadvertent trailing `+` is a binary operator
 *    - c * d +
 *    // and `-` is therefore a unary operator
 *    - e * f;
 *    // Therefore this is equivalent to `a * b - c * d + ((-e) * f)`
 * ```
 *
 * This could indicate that the author intended to use a binary
 * operator but left out one operand by accident, or as in the
 * example above accidentially wrote an unintended binary operator
 * and therefore made the `+` or `-` a unary operator by accident.
 *
 * Even if the usage of a unary plus or minus operator is intended,
 * the space between the operator and the operand should be removed
 * to improve readability.
 *
 * See also https://docs.oracle.com/javase/tutorial/java/nutsandbolts/operators.html
 */

import java

class PlusOrMinusExpr extends UnaryExpr {
    PlusOrMinusExpr() {
        this instanceof PlusExpr
        or this instanceof MinusExpr
    }
}

class ArithmeticBinaryExpr extends BinaryExpr {
    ArithmeticBinaryExpr() {
        this instanceof AddExpr
        or this instanceof SubExpr
        or this instanceof MulExpr
        or this instanceof DivExpr
        or this instanceof RemExpr
    }
}

from PlusOrMinusExpr expr, Location exprLocation, Expr operand, Location operandLocation
where
    // Only consider if parent is arithmetic expression as well
    (
        expr.getParent() instanceof ArithmeticBinaryExpr
        or expr.getParent() instanceof PlusOrMinusExpr
    )
    // Ignore if plus or minus expr is parenthesized because then usage
    // is likely not accidential
    and not expr.isParenthesized()
    and exprLocation = expr.getLocation()
    and operand = expr.getExpr()
    and operandLocation = operand.getLocation()
    and (
        // Either not in same line
        exprLocation.getStartLine() != operandLocation.getStartLine()
        // Or with at least one space between
        // Use getStartColumn of expr because end column would include operand
        // Get number of parentheses because they are not included in location,
        // see https://github.com/github/codeql/issues/3908
        or exists (int parentheses | 
            if operand.isParenthesized() then (
                isParenthesized(operand, parentheses)
            ) else (
                parentheses = 0
            )
        |
            operandLocation.getStartColumn() - exprLocation.getStartColumn() > 1 + parentheses
        )
    )
select expr
