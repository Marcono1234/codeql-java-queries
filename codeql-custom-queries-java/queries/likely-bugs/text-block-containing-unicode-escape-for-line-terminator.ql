/**
 * Finds text blocks which contain a Unicode escape sequence for a line
 * terminator character. Unicode escapes are replace during an early
 * stage or compilation, before incidental whitespaces are removed from
 * text blocks. This can lead to unexpected and incorrect results.
 * 
 * For example:
 * ```java
 * String value = """
 *     Spaces and line terminator:      \u000A  more spaces and next line
 *     """;
 * ```
 * Because the Unicode escape `\u000A` (LF) is replaced before removal of
 * incidental whitespaces, the value is the same as:
 * ```java
 * "  Spaces and line terminator:\nmore spaces and next line\n"
 * ```
 * 
 * The escape sequences `\n` (LF) and `\r` (CR) should be preferred
 * because they are replaced after incidental whitespaces have been
 * removed.
 * 
 * See also [Programmer's Guide to Text Blocks](https://docs.oracle.com/en/java/javase/16/text-blocks/index.html).
 */

 // Unicode escape sequences for spaces are covered by `text-block-containing-unicode-escape-for-space`

import java
import lib.Expressions
import lib.Strings

from TextBlock textBlock, string literal, string unicodeEscape, string unicodeEscapeHex, string alternative
where
    literal = textBlock.getLiteral()
    and unicodeEscape = getUnicodeEscape(literal, _, unicodeEscapeHex)
    and (
        unicodeEscapeHex = "000A" and alternative = "\\n"
        or unicodeEscapeHex = "000D" and alternative = "\\r"
    )
select textBlock, "Contains Unicode escape `" + unicodeEscape + "`; should use `" + alternative + "`"
