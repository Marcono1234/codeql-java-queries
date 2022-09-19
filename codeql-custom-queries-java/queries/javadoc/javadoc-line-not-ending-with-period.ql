/**
 * Finds lines in Javadoc comments which do not end with a period and where the next line
 * seems to be a separate sentence. Also keep in mind that line breaks in the documentation
 * comment are not preserved, so if the intention was to have a line break in the generated
 * documentation, an HTML tag has to be used.
 * 
 * Note that the precision of this query is rather low.
 * 
 * @kind problem
 */

import java

from JavadocParent parent, JavadocText missingPeriodText, JavadocText nextLineText, string firstWordInNextLine
where
    exists(missingPeriodText.getJavadoc().getCommentedElement())
    and parent = missingPeriodText.getParent()
    and nextLineText.getParent() = parent
    and missingPeriodText.getIndex() + 1 = nextLineText.getIndex()
    // Line which does not end with a period; only consider alpha-numeric suffixes to reduce false positives
    and missingPeriodText.getText().regexpMatch(".*[a-zA-Z0-9]\\s*")
    and nextLineText.getText().regexpMatch("[A-Z].*")
    // Ignore block tags where first text represents a separate value, e.g. `@param <parameter> <description>`
    and not (
        parent instanceof JavadocTag
        and missingPeriodText.getIndex() = 0
    )
    and firstWordInNextLine = nextLineText.getText().regexpCapture("^([a-zA-Z0-9]+).*", 1)
    // Ignore if word is completely uppercase
    and not (firstWordInNextLine.length() > 1 and firstWordInNextLine.isUppercase())
    // Ignore if uppercase word seems to be name of a type
    and not any(ClassOrInterface t).getName() = firstWordInNextLine
select missingPeriodText, "Line does not end with a period and next line seems to be a separate sentence"
