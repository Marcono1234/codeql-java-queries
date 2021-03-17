import java

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