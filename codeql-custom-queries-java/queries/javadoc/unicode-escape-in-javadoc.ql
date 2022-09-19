/**
 * Finds unicode escapes in javadoc comments, e.g.:
 * ```java
 * /**
 *  * Returns the unicode escape for the given char, e.g.
 *  * for {@code 'a'} it returns {@code "\u0061"}.
 *  * /
 * public String escape(char c) {
 *     ...
 * }
 * ```
 * Unicode escapes in Java source code are converted by the
 * pre-processor so even in javadoc, the escape would be replaced
 * with the respective character. This is often not desired or
 * another person reading the source code might not be aware of
 * this. If the HTML-based "Standard Doclet" is used, the
 * respective HTML character reference should be used instead of
 * the unicode escape, e.g. for `\` it would be `&#x005C;`.
 */

import java
import lib.Strings

from JavadocText javadocText, string unicodeEscape, string unicodeEscapeHex
where
    // JavadocText matches regular comments as well, see https://github.com/github/codeql/issues/3695
    // So make sure that it is actually a javadoc comment
    exists (javadocText.getParent+().(Javadoc).getCommentedElement())
    // Only match unescaped (= no leading backslash) unicode escape sequences since only
    // they are converted by preprocessor
    and unicodeEscape = getUnicodeEscape(javadocText.getText(), _, unicodeEscapeHex)
    // Ignore if escape represents backslash, escape is likely on purpose then
    and unicodeEscapeHex != "005C"
select javadocText, "Contains Unicode escape `" + unicodeEscape + "`"
