import java
import javadoc.lib.JavadocLib

from JavadocParent parent
where exists(Javadoc javadoc | javadoc = parent or javadoc.getAChild+() = parent |
    exists(javadoc.getCommentedElement())
)
select parent, getCompleteJavadocText(parent)
