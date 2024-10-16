/**
 * Finds redundant punctuation for Javadoc inline `{@return ...}` tags.
 * The tag automatically creates documentation in the form "Returns <text>.",
 * so there should not be any punctuation behind it since that would lead to
 * duplicate or incorrect punctuation.
 *
 * @kind problem
 * @id TODO
 */

import java
import lib.JavadocLib

from Javadoc javadoc, string text
where
  text = getCompleteJavadocText(javadoc) and
  exists(
    text.regexpFind([
        // TODO: Has false positives for embedded inline tag, e.g. `{@return ... {@code ...} ...}
        //    use own `JavadocLib.qll` for parsing inline tags?
        // Trailing punctuation in front of '}'
        "\\{@return\\s.+[.,:;-]\\s*\\}",
        // Trailing punctuaction or lowercase char behind '}'
        "\\{@return\\s.+\\}\\s*([.,:;-]|[a-z])",
      ], _, _)
  )
select javadoc, "Redundant punctuation or incorrectly capitalized text for `{@return ...}`"
