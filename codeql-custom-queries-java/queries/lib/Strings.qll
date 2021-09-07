
/**
 * Gets a non-escaped Java Unicode escape (`\uXXXX`) from the string
 * at the given index (starting at 0).
 * 
 * `hexValue` will be the hexadecimal value of the escape in uppercase.
 */
bindingset[s]
string getUnicodeEscape(string s, int index, string hexValue) {
    // 'u' can appear more than once
    result = s.regexpFind("\\\\u+[0-9a-fA-F]{4}", _, index)
    // And backslash of Unicode escape is not escaped
    and not s.prefix(index).regexpMatch("(?s).*(?<!\\\\)(\\\\\\\\)*\\\\")
    // Remove `\u` (and any additional 'u')
    and hexValue = result.suffix(result.length() - 4).toUpperCase()
}

private string getJavaWhitespaceRegex() {
    result = "(" +
        "[" +
            "\\p{Zs}" + // Category SPACE_SEPARATOR
            "\\p{Zl}" + // Category LINE_SEPARATOR
            "\\p{Zp}" + // Category PARAGRAPH_SEPARATOR
            // Exclusions
            "&&[^\\u00A0\\u2007\\u202F]" +
        "]" +
        "|" +
        "[" +
            "\\t" +
            "\\n" +
            "\\u000B" +
            "\\f" +
            "\\r" +
            "\\u001C" +
            "\\u001D" +
            "\\u001E" +
            "\\u001F" +
        "]" +
    ")+"
}

/**
 * Holds if the string consists only of whitespace characters, as defined by
 * Java's [`Character.isWhitespace`](https://docs.oracle.com/en/java/javase/16/docs/api/java.base/java/lang/Character.html#isWhitespace(int)).
 */
bindingset[s]
predicate consistsOnlyOfJavaWhitespaces(string s) {
    s.regexpMatch(getJavaWhitespaceRegex())
}

/**
 * Gets the leading whitespace characters, if any, as defined by
 * Java's [`Character.isWhitespace`](https://docs.oracle.com/en/java/javase/16/docs/api/java.base/java/lang/Character.html#isWhitespace(int)).
 */
bindingset[s]
string getLeadingJavaWhitespaces(string s) {
    result = s.regexpFind(getJavaWhitespaceRegex(), _, 0)
    and result != ""
}

/**
 * Gets a string consisting of the single character represented by the Unicode
 * hex value. For example for `00a7` the result is `§`.
 * 
 * Only 4-digit Unicode hex values are supported.
 */
bindingset[hexValue]
string getStringForUnicodeHex(string hexValue) {
    result = parseHexSigned(hexValue).toUnicode()
}

bindingset[s, times]
private string repeat(string s, int times) {
    result = concat(int i | i = [0 .. times - 1] | s)
}

/**
 * Gets the hexadecimal representation of the code point representing the
 * character in the form `U+XXXX` (with additional hex digits for
 * supplementary code points).
 * 
 * The string must either consist of a single char, or two chars forming a
 * valid surrogate pair, otherwise this predicate has no result.
 */
bindingset[character]
string getCodePointHex(string character) {
    exists(string hex, int codePoint |
        codePoint.toUnicode() = character
        and hex = unsignedToHex(codePoint)
        // Always use at least 4 hex digits
        and result = "U+" + repeat("0", 4 - hex.length()) + hex
    )
}

/**
 * Parses a hexadecimal string as a signed 32-bit integer. The string can consist
 * of lower- and uppercase hex digits, it must not have a sign. If the provided
 * string is not a valid hex string or its parsed value does not fit within the
 * 32-bit range this predicate has no result.
 */
// Based on https://github.com/github/codeql/issues/4145#issuecomment-681840831
bindingset[hexValue]
int parseHexSigned(string hexValue) {
    // Validate hex; do this here to prevent any case conversion 'surprises'
    forex(int i | i = [0 .. hexValue.length() - 1] |
        exists("0123456789abcdefABCDEF".indexOf(hexValue.charAt(i)))
    )
    // Prevent overflow
    and if (hexValue.length() > 8) then forall(int i | i = [0 .. hexValue.length() - 9] |
        hexValue.charAt(i) = "0"
    ) else any()
    and exists(string hexUpper | hexUpper = hexValue.toUpperCase() |
        result = sum(int i | |
            // * 4 because each hex digit represents 4 bits
            "0123456789ABCDEF".indexOf(hexUpper.charAt(i)).bitShiftLeft((hexUpper.length() - i - 1) * 4)
        )
    )
}

/**
 * Gets the hexadecimal representation of the value, using uppercase characters.
 * The int value will be treated as unsigned, the resulting hex value will not
 * have a minus sign when the int is negative. The result will only consist of
 * the hexadecimal digits, it won't have any special prefix.
 */
// Based on https://github.com/github/codeql/issues/4145#issuecomment-681840831
bindingset[value]
string unsignedToHex(int value) {
    result = strictconcat(int digit, int shiftedValue |
        digit in [0 .. 7]
        // * 4 because each hex digit represents 4 bits
        and shiftedValue = value.bitShiftRight(4 * digit)
        // Only use as much hex digits as needed, but at least one '0'
        and (digit = 0 or shiftedValue != 0)
    |
        "0123456789ABCDEF".charAt(shiftedValue.bitAnd(15)) order by digit desc
    )
}
