/**
 * Finds Unicode escapes (normally `\uXXXX`) which use multiple `u`s. While this
 * is permitted by the language specification, it does not add any value and
 * should be avoided because it might confuse readers.
 */

import java
import lib.Strings

from Top top, string unicodeEscape
where
    unicodeEscape = getUnicodeEscape([
        top.(JavadocText).getText(),
        top.(StringLiteral).getLiteral()
    ], _, _)
    and unicodeEscape.matches("\\uu%")
select top, "Contains Unicode escape `" + unicodeEscape + "` which uses multiple `u`s"
