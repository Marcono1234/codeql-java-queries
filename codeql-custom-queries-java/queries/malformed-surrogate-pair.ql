/**
 * Finds malformed surrogate pairs in string literals, i.e. a high surrogate followed
 * by something which is not a low surrogate and vice versa. Low surrogates at the
 * start of the string and high surrogates at the end of the string are ignored.
 *
 * Note that this will cause false negatives and false positives for surrogate chars
 * which are not unicode escaped.
 *
 * See also https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/lang/Character.html
 */

import java

bindingset[s]
string getMalformedSurrogatePair(string s) {
    /*
     * Captures a non-high surrogate (but not start of string) followed by a low surrogate
     * Or a low surrogate followed by a non-high surrogate (but not end of string)
     * Start and end of string are excluded because incomplete surrogate pairs might for example
     * be completed in concatenation
     *
     * See also https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/lang/Character.html
     */
    result = s.regexpCapture(
        "(?s)" // Have `.` match line terminators
        + ".*"
        + "("
        // Match low surrogate without high surrogate
            + "(?:"
                // Match escaped high surrogate
                + "(?:^|[^\\\\\\\\])"
                + "(?:\\\\\\\\)+u[dD][89aAbB][0-9a-fA-F]{2}"
            + "|"
                // Match anything other than high surrogate
                + "(?<!\\\\u[dD][89aAbB][0-9a-fA-F]{2})"
                // But not backslashes since they escape the low surrogate
                + "(?<!\\\\)"
            + "|"
                // Make sure that low surrogate is not escaped
                + "(?:^|[^\\\\])"
                + "(?:\\\\\\\\)+"
            + ")"
            // Don't match if low surrogate is at start of string
            + "(?<!^)"
            // Match low surrogate
            + "\\\\u[dD][c-fC-F][0-9a-fA-F]{2}"
        + "|"
        // Match high surrogate without low surrogate
            // Match non-escaped high surrogate
            + "(?<=^|[^\\\\])"
            + "(?:\\\\\\\\)*"
            + "\\\\u[dD][89aAbB][0-9a-fA-F]{2}"
            // Don't match if high surrogate is at end of string
            + "(?!$)"
            // Match anything other than low surrogate
            + "(?!\\\\u[dD][c-fC-F][0-9a-fA-F]{2})"
        + ")"
        + ".*",
        1
    )
}

from StringLiteral stringLiteral, string literal, string malformedSurrogatePair
where
    literal = stringLiteral.getLiteral()
    // `substring` to strip off leading and trailing double quote from string
    and malformedSurrogatePair = getMalformedSurrogatePair(literal.substring(1, literal.length() - 1))
select stringLiteral, malformedSurrogatePair
