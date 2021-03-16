/**
 * Finds lossy conversions of numeric literals to a smaller numeric type.
 */

import java
import lib.Literals

private class NumericOrCharTypeWithBounds extends Type {
    float minValue;
    float maxValue;

    NumericOrCharTypeWithBounds() {
        exists(PrimitiveType t, string n |
            (t = this or t = this.(BoxedType).getPrimitiveType())
            and n = t.getName()
        |
            // For byte and short consider max unsigned value as maxValue
            n = "byte" and minValue = -128 and maxValue = 255
            or n = "short" and minValue = -32768 and maxValue = 65535
            or n = "char" and minValue = 0 and maxValue = 65535
            or n = "int" and minValue = -2147483648 and maxValue = 2147483647
            // CodeQL int is only 32-bit, have to specify values as float
            or n = "long" and minValue = -9223372036854775808.0 and maxValue = 9223372036854775807.0
            or n = "float" and maxValue = "3.4028235E38".toFloat() and minValue = -maxValue
            // Don't have to consider double because its value range is the greatest

            // Conversion int -> float and long -> float/double can also be lossy,
            // but don't consider it because floating point is in general lossy
            // so might not have any negative effect
        )
    }

    float getMinValue() {
        result = minValue
    }

    float getMaxValue() {
        result = maxValue
    }
}

class NumericOrCharLiteral extends Expr {
    float value;

    NumericOrCharLiteral() {
        // Either match a positive literal, or a MinusExpr in front of a literal
        value = getNumericValue(this) and not any(MinusExpr minus).getExpr() = this
        or value = -getNumericValue(this.(MinusExpr).getExpr())
    }

    float getNumericValue() {
        result = value
    }
}

private class ConversionExpr extends Expr {
    NumericOrCharTypeWithBounds destType;
    NumericOrCharLiteral converted;

    ConversionExpr() {
        exists(CastExpr cast | cast = this |
            destType = cast.getType()
            and converted = cast.getExpr()
        )
        // Compound assignment performs implicit conversion
        or exists(AssignOp compoundAssign | compoundAssign = this |
            destType = compoundAssign.getType()
            and converted = compoundAssign.getRhs()
        )
    }

    NumericOrCharTypeWithBounds getDestType() {
        result = destType
    }

    NumericOrCharLiteral getConverted() {
        result = converted
    }
}

bindingset[f, other]
private predicate lessThan(float f, float other) {
    f < other
    // CodeQL considers -0f < 0f
    and not (f = -0.0 and other = 0.0)
}

from ConversionExpr conv, NumericOrCharTypeWithBounds destType, NumericOrCharLiteral literal, float literalValue
where
    destType = conv.getDestType()
    and literal = conv.getConverted()
    and literalValue = literal.getNumericValue()
    and (lessThan(literalValue, destType.getMinValue()) or literalValue > destType.getMaxValue())
select conv, "Performs lossy conversion of $@ to smaller type " + destType.getName(),
    literal, "this literal"
