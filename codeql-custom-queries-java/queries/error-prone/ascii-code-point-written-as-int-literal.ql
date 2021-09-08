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
 */

import java
import semmle.code.java.Conversions

from IntegerLiteral intLiteral, int codePoint, string asciiChar
where
    intLiteral.(ConversionSite).getConversionTarget() instanceof CharacterType
    and codePoint = intLiteral.getIntValue()
    and codePoint in [32 .. 126]
    and asciiChar = codePoint.toUnicode()
select intLiteral, "Uses int literal instead of char literal for printable ASCII char '" + asciiChar + "'"
