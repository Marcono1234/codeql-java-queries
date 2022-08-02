/**
 * Finds comparison and equality test expressions where one operand unnecessarily
 * is a literal of a wider type.
 * 
 * For example for an `int` variable `x` the comparison `x < 3L` should be changed
 * to use an integer literal `3` instead of a `long` literal for better readability.
 */

/*
 * Does not in general detect `long` or floating point literals which could be
 * simplified to `int` literals (e.g. `4L` → `4` or `4.0` → `4`) because the intention
 * of the author might be to highlight that the comparison is comparing `long` or
 * floating point types.
 */

import java

class ComparisonOrEqualityTest extends BinaryExpr {
    ComparisonOrEqualityTest() {
        this instanceof ComparisonExpr
        or this instanceof EqualityTest
    }
}

class LongType extends Type {
    LongType() {
        this.(PrimitiveType).hasName("long")
        or this.(BoxedType).hasName("Long")
    }
}

// Note: Does not work for values outside `int` range because CodeQL has no primitive type for 64-bit `long`
int getAlternativeIntValue(ComparisonOrEqualityTest comparingExpr, Literal literalOperand) {
    exists(float floatValue |
        floatValue = [
            literalOperand.(FloatLiteral).getFloatValue(),
            literalOperand.(DoubleLiteral).getDoubleValue()
        ]
    |
        comparingExpr instanceof ComparisonExpr
        and (
            // Get the next closer int depending on whether literal is lesser operand
            if literalOperand = comparingExpr.(ComparisonExpr).getLesserOperand()
            then result = floatValue.floor()
            else result = floatValue.ceil()
        )
        or
        // For EqualityTest get the int value
        result = floatValue.(int)
    )
}

from ComparisonOrEqualityTest comparingExpr, Literal literalOperand, Expr otherOperand, string message
where
    literalOperand = comparingExpr.getAnOperand()
    and otherOperand = comparingExpr.getAnOperand()
    and literalOperand != otherOperand
    and (
        otherOperand.getType() instanceof IntegralType
        and literalOperand.getType() instanceof FloatingPointType
        and message = "Could be changed to integral literal " + getAlternativeIntValue(comparingExpr, literalOperand)
        or
        otherOperand.getType() instanceof IntegralType
        and not otherOperand.getType() instanceof LongType
        and message = "Could be changed to integer literal " + literalOperand.(LongLiteral).getValue()
    )
select literalOperand, message
