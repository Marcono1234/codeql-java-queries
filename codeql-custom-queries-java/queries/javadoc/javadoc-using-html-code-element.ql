/**
 * Finds Javadoc comments which use the HTML element `<code>...</code>`
 * instead of the inline Javadoc tag `{@code ...}` of the Standard Doclet.
 */

import java

from JavadocText javadocText, string text, string htmlCodeElement
where
    // Only match JavadocText if there is a commented element
    exists (javadocText.getParent+().(Javadoc).getCommentedElement())
    and text = javadocText.getText()
    // Find `<code>...</code>` (case insensitively) which does not appear to contain a nested HTML element,
    // '{' or '}' (since it might not be possible to use `{@code ...}` then)
    and htmlCodeElement = text.regexpFind("(?i)<code>[^<{}]*</code>", _, _)
select javadocText, "Uses  HTML element '" + htmlCodeElement + "' instead of Javadoc tag {@code ...}"
