/**
 * Finds text blocks which contain a Unicode escape sequence for a space
 * character for which an escape sequence exists. Unicode escapes are replaced
 * during an early stage or compilation, before incidental whitespaces are
 * removed from text blocks. Usage of Unicode escapes in text blocks can
 * therefore lead to unexpected and incorrect results.
 * 
 * For example:
 * ```java
 * String value = """
 *     Trailing spaces:      \u0020
 *     """;
 * ```
 * Because the Unicode escape `\u0020` (whitespace) is replaced before
 * removal of incidental whitespaces, the value is the same as:
 * ```java
 * "Trailing spaces:\n"
 * ```
 * 
 * Even if the Unicode escape sequence is neither at the beginning nor
 * at the end of a line (and therefore not affected by removal of incidental
 * whitespaces), it can be error-prone nonetheless when in the future the
 * source code is wrapped and the Unicode escape sequence moves to the start
 * or end of a line.
 * 
 * See also [Programmer's Guide to Text Blocks](https://docs.oracle.com/en/java/javase/16/text-blocks/index.html).
 */

import java
import lib.Expressions
import lib.Strings

// Note: Has some overlap with `text-block-leading-or-trailing-space-unicode-escape`
// but this query here finds usage of Unicode escape sequence anywhere in text block
// instead of only leading or trailing ones; and also this query only covers Unicode
// escape sequences for which an alternative escape sequence exists

from TextBlock textBlock, string literal, string unicodeEscape, string unicodeEscapeHex, string alternative
where
    literal = textBlock.getLiteral()
    and unicodeEscape = getUnicodeEscape(literal, _, unicodeEscapeHex)
    and (
        unicodeEscapeHex = "0020" and alternative = "\\s"
        or unicodeEscapeHex = "0009" and alternative = "\\t"
        or unicodeEscapeHex = "000C" and alternative = "\\f"
        // Line terminators are handled by query `text-block-containing-unicode-escape-for-line-terminator`
        // before that nearly always results in incorrect behavior
    )
select textBlock, "Contains Unicode escape `" + unicodeEscape + "`; should use `" + alternative + "`"
