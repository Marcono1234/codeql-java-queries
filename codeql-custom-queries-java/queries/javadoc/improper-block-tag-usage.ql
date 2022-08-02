/**
 * Finds incorrect usage of javadoc block tags. For example when there is text in front of
 * the block tag, it is not recognized as block tag. This also detects erroneous usage of
 * block tags as inline tags, for example `{@see String}`. No text is displayed for this
 * in the generated javadoc. (For this specific case the correct inline tag is `{@link ...}`.)
 * 
 * @kind problem
 */

import java
import lib.JavadocLib

from JavadocText javadocText, string tag
where
    // Javadoc also matches regular comment, so make sure it is actually javadoc
    exists(javadocText.getJavadoc().getCommentedElement())
    and exists(string text, boolean isAlsoInlineTag, int index |
        text = javadocText.getText()
        and isBlockTagName(tag, isAlsoInlineTag)
        and index = text.indexOf("@" + tag)
        // Ignore if used as inline tag
        and not (isAlsoInlineTag = true and text.charAt(index - 1) = "{")
    )
select javadocText, "Block tag @" + tag + " is not used correctly"
