/**
 * Finds unicode and octal escape sequences within a `char` or
 * string literal which represents a printable ASCII char.
 * For better readiblity the char should be written unescaped.
 */

import java

bindingset[s]
predicate isUnicodeEscape(string s) {
    s.indexOf("\\u") = 0
}

bindingset[c]
int hexCharToInt(string c) {
    result = c.toInt() // 0 - 9
    or exists (string upper |
        upper = c.toUpperCase()
        and (
            (upper = "A" and result = 10)
            or (upper = "B" and result = 11)
            or (upper = "C" and result = 12)
            or (upper = "D" and result = 13)
            or (upper = "E" and result = 14)
            or (upper = "F" and result = 15)
        )
    )
}

bindingset[escape]
int unicodeEscapeToCodePoint(string escape) {
    result = (
        // Start at 2 to skip `\u`
        hexCharToInt(escape.charAt(5))
        + hexCharToInt(escape.charAt(4)) * 16
        + hexCharToInt(escape.charAt(3)) * 16 * 16
        + hexCharToInt(escape.charAt(2)) * 16 * 16 * 16
    )
}


bindingset[escape]
int octalEscapeToCodePoint(string escape) {
    if escape.length() > 3 then (
        result = (
            // Start at 1 to skip `\`
            escape.charAt(3).toInt()
            + escape.charAt(2).toInt() * 8
            + escape.charAt(1).toInt() * 8 * 8
        )
    )
    else if escape.length() > 2 then (
        result = (
            // Start at 1 to skip `\`
            escape.charAt(2).toInt()
            + escape.charAt(1).toInt() * 8
        )
    )
    else (
        result = (
            // Start at 1 to skip `\`
            escape.charAt(1).toInt()
        )
    )
}

bindingset[s]
int getAnEscapedCodePoint(string s, string escaped) {
    // Captures an escape sequence (unicode or octal) including the
    // leading backslash
    escaped = s.regexpCapture(".*?(?:^|[^\\\\])(?:\\\\\\\\)*(\\\\(?:u[0-9a-fA-F]{4}|[0-3][0-7]{0,2}|[0-7]{1,2})).*?", 1)
    and if isUnicodeEscape(escaped) then (
        result = unicodeEscapeToCodePoint(escaped)
    ) else (
        result = octalEscapeToCodePoint(escaped)
    )
}

bindingset[codePoint]
predicate isPrintableAscii(int codePoint) {
    codePoint >= 32 and codePoint <= 126
}

from Literal literal, int codePoint, string escaped
where
    (
        // For char literal check complete literal as well since it
        // could contain escaped backslash and escaped other char, e.g.:
        // '\u005C\u0074' instead of '\t'
        literal instanceof CharacterLiteral
        or literal instanceof StringLiteral
    )
    and codePoint = getAnEscapedCodePoint(literal.getLiteral(), escaped)
    and isPrintableAscii(codePoint)
select literal, escaped
