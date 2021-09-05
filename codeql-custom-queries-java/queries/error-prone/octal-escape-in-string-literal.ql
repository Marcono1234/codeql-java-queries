/**
 * Finds octal escapes in string literals. Octal escapes are not very common and
 * might therefore be confused with Unicode escapes.
 * 
 * Instead of octal escapes Unicode escapes (`\uXXXX`) should be preferred.
 * 
 * See also [JLS 16 §3.10.7: Escape Sequences](https://docs.oracle.com/javase/specs/jls/se16/html/jls-3.html#jls-3.10.7).
 */

// Similar to CodeQL's java/octal-literal for integer literals

import java

from StringLiteral l, string literal, int index, string octalEscape
where
    literal = l.getLiteral()
    and octalEscape = literal.regexpFind("\\\\[0-3][0-7]{2}|\\\\[0-7]{1,2}", _, index)
    // And make sure '\' of octal escape is not escaped
    and literal.prefix(index).regexpMatch(".*(?<!\\\\)(\\\\\\\\)*")
    // Ignore "\0" which is rather common
    and octalEscape != "\\0"
select l, "Contains octal escape '" + octalEscape + "'"
