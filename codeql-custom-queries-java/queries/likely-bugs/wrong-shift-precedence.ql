/**
 * Finds bitwise shift expressions where one of the operands is an arithmetic expression
 * and it appears the author intended to instead first evaluate the shift expression and
 * then the arithmetic expression, e.g.:
 * ```
 * int mask = 1 << (BIT_POS + 1) - 1;
 * ```
 * Here it appears the author intended to first calculate `1 << (BIT_POS + 1)` and then
 * subtract 1. However, due to the precedence rules, the complete arithmetic is evaluated
 * first and afterwards the shift is performed.
 * 
 * See also https://docs.oracle.com/javase/tutorial/java/nutsandbolts/operators.html
 */

import java

class ShiftExpr extends BinaryExpr {
    ShiftExpr() {
        this instanceof LShiftExpr
        or this instanceof RShiftExpr
        or this instanceof URShiftExpr
    }
}

abstract class ArithmeticExpr extends BinaryExpr {
    abstract int getPrecedence();
}

class AddOrSubExpr extends ArithmeticExpr {
    AddOrSubExpr() {
        this instanceof AddExpr
        or this instanceof SubExpr
    }
    
    override int getPrecedence() {
        result = 3
    }
}

class MulOrDivExpr extends ArithmeticExpr {
    MulOrDivExpr() {
        this instanceof MulExpr
        or this instanceof DivExpr
        or this instanceof RemExpr
    }
    
    override int getPrecedence() {
        result = 2
    }
}

from ShiftExpr shift, ArithmeticExpr operand
where
    // Ignore if the operand is parenthesized because then the precedence is likely as intended
    not operand.isParenthesized()
    // And the sub-operand on the side of the shift is an arithmetic expression as well which is
    // parenthesized (and not due to precedence requirements); see example in query description
    and (
        (
            operand = shift.getLeftOperand()
            and operand.getRightOperand().isParenthesized()
            // And parentheses are not necessary due to different precedence
            and not operand.getRightOperand().(ArithmeticExpr).getPrecedence() > operand.getPrecedence()
        )
        or (
            operand = shift.getRightOperand()
            and operand.getLeftOperand().isParenthesized()
            // And parentheses are not necessary due to different precedence
            and not operand.getLeftOperand().(ArithmeticExpr).getPrecedence() > operand.getPrecedence()
        )
    )
select shift, operand
