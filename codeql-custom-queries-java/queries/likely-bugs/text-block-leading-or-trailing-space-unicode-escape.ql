/**
 * Finds text blocks which for which a line starts with or ends with a Unicode
 * escape sequence for a space character. Unicode escapes are replaced
 * during an early stage or compilation, before incidental whitespaces are
 * removed from text blocks. Therefore the space character represented by
 * the Unicode escape might not actually remain in the string value.
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
 * See also [Programmer's Guide to Text Blocks](https://docs.oracle.com/en/java/javase/16/text-blocks/index.html).
 */

import java
import lib.Expressions
import lib.Strings

bindingset[s]
boolean emptyOrOnlyWhitespaces(string s) {
    if (s = "" or consistsOnlyOfJavaWhitespaces(s)) then result = true
    else result = false
}

string getAlternative(string hexValue) {
    hexValue = "0020" and result = "\\s"
    or hexValue = "0009" and result = "\\t"
    or hexValue = "000C" and result = "\\f"
}

// Note: Has some overlap with `text-block-containing-unicode-escape-for-space`
// but this query here only finds leading and trailing usage of Unicode escape sequences
// which most likely always gives unexpected results

from TextBlock textBlock, string literalLine, int index, string unicodeEscape, string unicodeEscapeHex, string messagePrefix, string alternativeMessage
where
    literalLine = textBlock.getLiteralLine(_)
    and unicodeEscape = getUnicodeEscape(literalLine, index, unicodeEscapeHex)
    // And represented character would be considered incidental whitespace
    and consistsOnlyOfJavaWhitespaces(getStringForUnicodeHex(unicodeEscapeHex))
    // And verify that Unicode escape is either leading or trailing
    and exists(int endIndexExclusive, boolean prefixEmpty, boolean suffixEmpty |
        endIndexExclusive = index + unicodeEscape.length()
        and prefixEmpty = emptyOrOnlyWhitespaces(literalLine.prefix(index))
        and suffixEmpty = emptyOrOnlyWhitespaces(literalLine.suffix(endIndexExclusive))
    |
        if (prefixEmpty = true and suffixEmpty = true) then (
            messagePrefix = "Empty line contains"
        ) else if (prefixEmpty = true) then (
            messagePrefix = "Contains leading"
        ) else if (suffixEmpty = true) then (
            messagePrefix = "Contains trailing"
        ) else none()
    )
    // Get alternative message, if any
    and (
        if (exists(getAlternative(unicodeEscapeHex))) then (
            alternativeMessage = "; should use `" + getAlternative(unicodeEscapeHex) + "`"
        ) else (
            // No alternative?
            alternativeMessage = ""
        )
    )
select textBlock, messagePrefix + " Unicode escape `" + unicodeEscape + "`" + alternativeMessage
