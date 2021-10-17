import java

/**
 * Numeric literal with value 0.
 */
class LiteralZero extends Literal {
    LiteralZero() {
        this.(IntegerLiteral).getIntValue() = 0
        or this.(LongLiteral).getValue() = "0"
        or this.(FloatingPointLiteral).getFloatValue() = 0
        or this.(DoubleLiteral).getDoubleValue() = 0
    }
}

/**
 * Numeric literal of type `int` or `long` with value 0.
 */
class LiteralIntegralZero extends LiteralZero {
    LiteralIntegralZero() {
        this instanceof IntegerLiteral
        or this instanceof LongLiteral
    }
}

/**
 * Numeric literal with value 1.
 */
class LiteralOne extends Literal {
    LiteralOne() {
        this.(IntegerLiteral).getIntValue() = 1
        or this.(LongLiteral).getValue() = "1"
        or this.(FloatingPointLiteral).getFloatValue() = 1
        or this.(DoubleLiteral).getDoubleValue() = 1
    }
}

/**
 * Gets the numeric value of the literal as CodeQL `float` in case the literal represents
 * a numeric or `char` literal.
 */
float getNumericValue(Literal l) {
    result = [
        // TODO: Cannot get code point value of char, see https://github.com/github/codeql/issues/3635

        l.(IntegerLiteral).getIntValue(),
        // Has no predicate for getting long value; therefore parse as CodeQL float
        l.(LongLiteral).getValue().toFloat(),
        l.(FloatingPointLiteral).getValue().toFloat(),
        l.(DoubleLiteral).getValue().toFloat()
    ]
}
