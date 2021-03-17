/**
 * Finds `float` literals whose value written in source cannot be represented
 * exactly as 32-bit Java `float`. If the value should be more precise, `double`
 * or `BigDecimal` should be used instead.
 */

import java

from FloatingPointLiteral literal, string sourceValue, float parsedSourceValue, string rounded
where
    /*
     * Parse toString() as CodeQL 64-bit float which has higher precision,
     * then compare with getValue() which has value with precision of 32-bit
     * Java float as result
     *
     * Use extra variable (instead of directly comparing parsed) to make sure
     * toString() can actually be parsed
     * 
     * Note: toString() result is implementation detail; might break in the future
     */

    sourceValue = literal.toString()
    /*
     * Ignore if written in hexadecimal notation; getValue() will return its
     * rounded scientific value (e.g. 12E30) which will yield different result
     * when parsed as 64-bit CodeQL float (and therefore cause false positive)
     */
    and not exists(sourceValue.indexOf(["0x", "0X"]))
    and parsedSourceValue = sourceValue.toFloat()
    // getValue() has value with precision of 32-bit Java float as result
    and rounded = literal.getValue()
    and rounded.toFloat() != parsedSourceValue
select literal, "Literal value cannot be exactly represented as float, will be rounded to " + rounded
