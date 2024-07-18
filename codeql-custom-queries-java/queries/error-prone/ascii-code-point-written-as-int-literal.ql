/**
 * Finds `int` literals which are converted to `char`, but represent a
 * printable ASCII char. In this case a `char` literal should be used
 * instead. E.g.:
 * ```java
 * public boolean isLowerCase(char c) {
 *     // Should use 'a' and 'z' instead of int literals
 *     return c >= 97 && c <= 122;
 * }
 * ```
 *
 * @kind problem
 * @id TODO
 */

import java
import semmle.code.java.Conversions

predicate isUsedAsChar(IntegerLiteral intLiteral) {
  intLiteral.(ConversionSite).getConversionTarget() instanceof CharacterType and
  // Ignore if used in arithmetic operation; probably only have to consider AssignOp (e.g. `+=`) because for
  // other arithmetic operations implicit conversion to greater numeric type (e.g. `int`) occurs (?)
  not any(AssignOp a).getRhs() = intLiteral
  or
  // Or comparing with a char value
  exists(BinaryExpr comp |
    comp instanceof EqualityTest
    or
    comp instanceof ComparisonExpr and
    // But only consider when comparing with an alpha-numeric char (a-z, A-Z, 0-9)
    // Control code checks such as `c < 0x20` might be easier to understand than `c < ' '`
    exists(int codePoint | codePoint = intLiteral.getIntValue() |
      codePoint = [97 .. 122] or codePoint = [65 .. 90] or codePoint = [48 .. 57]
    )
  |
    comp.getAnOperand() = intLiteral and comp.getAnOperand().getType() instanceof CharacterType
  )
  or
  // Or calling `Character.equals`
  exists(MethodAccess equalsCall |
    equalsCall.getMethod() instanceof EqualsMethod and
    equalsCall.getQualifier().getType().(RefType).hasQualifiedName("java.lang", "Character") and
    equalsCall.getArgument(0) = intLiteral
  )
}

from IntegerLiteral intLiteral, int codePoint, string asciiChar
where
  isUsedAsChar(intLiteral) and
  codePoint = intLiteral.getIntValue() and
  codePoint in [32 .. 126] and
  asciiChar = codePoint.toUnicode()
select intLiteral,
  "Uses int literal instead of char literal for printable ASCII char '" + asciiChar + "'"
