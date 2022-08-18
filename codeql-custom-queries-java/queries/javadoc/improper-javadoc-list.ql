/**
 * Finds Javadoc which uses `- `, `* ` or `1. ` to create lists. This will most likely not
 * create the desired formatting because Javadoc has to be written by default using HTML,
 * so this text will just be displayed in a single line instead of being shown as proper
 * list.
 * 
 * @kind problem
 */

import java

predicate looksLikeListItem(JavadocText javadocText) {
    exists(javadocText.getText().trim().regexpFind("[-*]\\s|\\d\\.", _, 0))
}

// Note: This implementation relies on each line being a separate JavadocText, see https://github.com/github/codeql/issues/3696

// Use JavadocParent to also match text in block tags
from JavadocParent parent, JavadocText listText, int index
where
    exists(Javadoc javadoc, Modifiable documented | javadoc = parent or javadoc.getAChild+() = parent |
        // Javadoc also matches regular comment, this additionally makes sure it is actually javadoc
        documented = javadoc.getCommentedElement()
        // Only consider publicly visible documentation; ignore internal documentation comments
        and (
            documented.isProtected()
            or documented.isPublic()
        )
    )
    and listText = parent.getChild(index)
    and looksLikeListItem(listText)
    // And to reduce false positives make sure next line looks like list item as well
    and looksLikeListItem(parent.getChild(index + 1))
    // Ignore if there is list item before current one; only report the first one
    and not looksLikeListItem(parent.getChild(index - 1))
select listText, "Not a proper Javadoc list"
