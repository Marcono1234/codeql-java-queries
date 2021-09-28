/**
 * Finds Javadoc inline tags which themselves contain inline tags as content.
 * Java versions below 17 do not support nested inline tags, they will be displayed
 * as is in the created documentation. Starting with Java 17 nested inline tags are
 * supported, see [JDK-8257925](https://bugs.openjdk.java.net/browse/JDK-8257925).
 */

import java
import lib.JavadocLib

// TODO: Are in general nested inline tags are not supported, or only for some kinds?

// Note: Does not support multiline inline tags, but it is unlikely that they contain
// nested inline tags
from JavadocText javadocText, string inlineTag, string tagContent, string nestedInlineTag
where
    // Make sure this is not a regular comment, see https://github.com/github/codeql/issues/3695
    exists(javadocText.getJavadoc().getCommentedElement())
    and exists(string text, int index, int length |
        text = javadocText.getText()
        and tagContent = getInlineTagContent(
            text,
            _,
            index,
            length
        )
        and inlineTag = text.substring(index, index + length)
    )
    and exists(int index, int length |
        exists(getInlineTagContent(tagContent, _, index, length))
        and nestedInlineTag = tagContent.substring(index, index + length)
    )
select javadocText, "Inline tag `" + inlineTag + "` contains nested inline tag `" + nestedInlineTag + "`"
