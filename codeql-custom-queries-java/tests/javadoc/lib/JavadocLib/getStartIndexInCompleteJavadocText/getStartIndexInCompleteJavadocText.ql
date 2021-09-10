import java
import javadoc.lib.JavadocLib

from JavadocText javadocText
where exists(javadocText.getJavadoc().getCommentedElement())
select javadocText, getStartIndexInCompleteJavadocText(javadocText.getParent(), javadocText)
