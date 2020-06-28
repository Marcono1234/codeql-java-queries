/**
 * Finds Javadoc block tag texts which have a leading hyphen (`-`).
 * The Javadoc Standard Doclet displays all tags in a way that the text of
 * the tag is separate from other content, so adding a `-` in the text as
 * separator is not necessary and can even create redundant Javadoc output,
 * e.g. for parameters it creates:
 * ```
 * paramName - - description
 * ```
 * instead of the desired
 * ```
 * paramName - description
 * ```
 */

import java

from JavadocTag javadocTag, string text
where
    text = javadocTag.getText()
    // Match `-` followed by something which is not a number
    and text.regexpMatch("[ \t]*-[^\\d].*")
select javadocTag, text
