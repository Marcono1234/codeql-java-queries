/**
 * Finds implicit conversion from an integer literal in non-decimal notation with
 * a negative value to the smaller integral types `byte` and `short`.
 * When determining whether an integer literal is within the range of the target
 * type, the compiler always considers the decimal value of the literal. Therefore
 * it allows usage of non-decimal literals which use more bits than the target type
 * support. For example, the following assignment is valid:
 * ```java
 * // byte only has 8 bits, but decimal value of literal is -1 which is within
 * // value range of byte
 * byte b = 0b1111_1111_1111_1111_1111_1111_1111_1111;
 * ```
 * 
 * Such code is rather misleading and might lead to errors in the future. Instead
 * it might be better to only write literals whose represented number of bits is
 * at most the same as the number of bits the target type supports and then cast
 * the literal. For example:
 * ```java
 * byte b = (byte) 0b1111_1111;
 * ```
 * 
 * This query is based on [Java Puzzlers, Strange Loop Edition](https://youtu.be/qRTIpyd_snc?t=1568).
 */

/*
 * Note: This has been categorized as 'error-prone' instead of 'likely-bugs' because the cut off
 * high bits all have to be 1 (otherwise the value would be out of range), so there is likely
 * no information loss
 */

import java
import semmle.code.java.Conversions

class SmallIntegralType extends Type {
    SmallIntegralType() {
        exists(PrimitiveType p |
            p = this or p = this.(BoxedType).getPrimitiveType()
        |
            p.hasName(["byte", "short"])
        )
    }
}

/**
 * Holds if the literal is non-decimal and uses the maximum number
 * of digits. This is the case for non-decimal negative values because
 * the most significant bit has to be set for them to be negative.
 */
private predicate usesMaxDigits(IntegerLiteral literal) {
    literal.getIntValue() < 0
    and literal.getLiteral().regexpMatch([
        // Hexadecimal
        "0[xX].+",
        // Octal
        "0[_\\d].+",
        // Binary
        "0[bB].+"
    ])
}

from ConversionSite conversionSite, IntegerLiteral integerLiteral, SmallIntegralType type
where
    conversionSite = integerLiteral
    and usesMaxDigits(integerLiteral)
    and conversionSite.getConversionTarget() = type
    // Only consider implicit conversion, ignore explicit cast
    and conversionSite.isImplicit()
select integerLiteral, "Literal uses more bits than target type " + type.getName()
