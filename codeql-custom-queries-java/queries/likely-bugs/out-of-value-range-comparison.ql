/**
 * Finds comparisons which are always true or false because the fixed value against
 * which the comparison is performed is outside the value range of the other argument.
 * For example:
 * ```java
 * byte b = ...;
 * // Always true because a byte value is always smaller than Integer.MAX_VALUE
 * if (b < Integer.MAX_VALUE) {
 *     ...
 * }
 * ```
 * 
 * See also Error Prone pattern [ComparisonOutOfRange](https://errorprone.info/bugpattern/ComparisonOutOfRange).
 * 
 * @kind problem
 */

import java

// Use float as return type because CodeQL's int type is only 32 bit and therefore cannot store all Java (64-bit) long values
float getFloatValue(Expr e) {
  result = e.(CompileTimeConstantExpr).getIntValue()
  or result = e.(LongLiteral).getValue().toFloat()
  or result = e.(CharacterLiteral).getCodePointValue()
  or result = e.(FloatLiteral).getFloatValue()
  or result = e.(DoubleLiteral).getDoubleValue()
  or exists(Field f, string t |
    f.getDeclaringType().hasQualifiedName("java.lang", t)
    and f.hasName("MIN_VALUE")
    and e = f.getAnAccess()
  |
    t = "Byte" and result = -128
    or t = "Short" and result = -32768
    or t = "Character" and result = 0
    or t = "Integer" and result = -2147483648
    // Note: Cannot be accurately represented as CodeQL float
    or t = "Long" and result = -9223372036854775808.0
    // Don't include Float and Double; unlikely that comparisons are
    // performed against their min values
  )
  or exists(Field f, string t |
    f.getDeclaringType().hasQualifiedName("java.lang", t)
    and f.hasName("MAX_VALUE")
    and e = f.getAnAccess()
  |
    t = "Byte" and result = 127
    or t = "Short" and result = 32767
    or t = "Character" and result = 65535
    or t = "Integer" and result = 2147483647
    // Note: Cannot be accurately represented as CodeQL float
    or t = "Long" and result = 9223372036854775807.0
    // Don't include Float and Double; unlikely that comparisons are
    // performed against their max values
  )
  // Other Character MIN and MAX values
  or exists(Field f, string n |
    f.getDeclaringType().hasQualifiedName("java.lang", "Character")
    and f.hasName(n)
    and e = f.getAnAccess()
  |
    n = "MAX_CODE_POINT" and result = 1114111
    or n = "MAX_HIGH_SURROGATE" and result = 56319
    or n = "MAX_LOW_SURROGATE" and result = 57343
    or n = "MAX_SURROGATE" and result = 57343
    or n = "MIN_CODE_POINT" and result = 0
    or n = "MIN_HIGH_SURROGATE" and result = 55296
    or n = "MIN_LOW_SURROGATE" and result = 56320
    or n = "MIN_SURROGATE" and result = 55296
  )
}

float getMinValue(PrimitiveType t) {
  t.hasName("byte") and result = -128
  or t.hasName("short") and result = -32768
  or t.hasName("char") and result = 0
  or t.hasName("int") and result = -2147483648
  // Note: Cannot be accurately represented as CodeQL float
  or t.hasName("long") and result = -9223372036854775808.0
  // Don't include float and double because it is unlikely that any comparison is
  // performad against their min value (or smaller numbers)
}

float getMaxValue(PrimitiveType t) {
  t.hasName("byte") and result = 127
  or t.hasName("short") and result = 32767
  or t.hasName("char") and result = 65535
  or t.hasName("int") and result = 2147483647
  // Note: Cannot be accurately represented as CodeQL float
  or t.hasName("long") and result = 9223372036854775807.0
  // Don't include float and double because it is unlikely that any comparison is
  // performad against their max value (or larger numbers)
}

from BinaryExpr comparingExpr, Expr e, Expr fixedValueExpr, float comparedValue, PrimitiveType type, float minValue, float maxValue, string message
where
  comparingExpr.getAnOperand() = e
  and comparingExpr.getAnOperand() = fixedValueExpr
  and comparedValue = getFloatValue(fixedValueExpr)
  and e != fixedValueExpr
  and (type = e.getType() or type = e.getType().(BoxedType).getPrimitiveType())
  and minValue = getMinValue(type)
  and maxValue = getMaxValue(type)
  and (
    exists(EqualityTest eqTest | eqTest = comparingExpr |
      comparedValue < minValue and (if eqTest.polarity() = true then
        // e == (min - x)
        message = "Always false because $@ is smaller than min value"
        // e != (min - x)
        else message = "Always true because $@ is smaller than max value"
      )
      or comparedValue > maxValue and (if eqTest.polarity() = true then
        // e == (max + x)
        message = "Always false because $@ is greater than max value"
        // e != (max + x)
        else message = "Always true because $@ is greater than max value"
      )
    )
    or exists(ComparisonExpr compExpr | compExpr = comparingExpr |
      comparedValue < minValue and (if e = compExpr.getGreaterOperand() then
        // e > (min - x) || e >= (min - x)
        message = "Always true because $@ is smaller than min value"
        // e < (min - x) || e <= (min - x)
        else message = "Always false because $@ is smaller than min value"
      )
      or comparedValue > maxValue and (if e = compExpr.getGreaterOperand() then
        // e > (max + x) || e >= (max + x)
        message = "Always false because $@ is greater than max value"
        // e < (max + x) || e <= (max + x)
        else message = "Always true because $@ is greater than max value"
      )
      or compExpr.isStrict() and (
        // e > max
        comparedValue >= maxValue and e = compExpr.getGreaterOperand() and message = "Always false because $@ is greater than or equal to max value"
        // e < min
        or comparedValue <= minValue and e = compExpr.getLesserOperand() and message = "Always false because $@ is smaller than or equal to min value"
      )
    )
  )
select comparingExpr, message + " of type " + type.getName(), fixedValueExpr, "this value"
