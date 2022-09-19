/**
 * Finds Javadoc comments which don't seem to document any element. This might indicate that
 * the Javadoc comment is incorrectly placed or might be a left-over from refactoring.
 * 
 * @kind problem
 */

import java

from Javadoc javadoc
where
    // Javadoc also matches regular block and EOL comments; ignore those
    not isNormalComment(javadoc)
    and not exists(javadoc.getCommentedElement())
    // Ignore documentated `package-info.java`, does not seem to be covered by `getCommentedElement()`
    and not javadoc.getFile().(CompilationUnit).hasName("package-info")
    // Ignore license header texts; these are (erroneously?) often Javadoc comments
    and not exists(JavadocText text | text.getJavadoc() = javadoc |
        exists(text.getText().regexpFind("(?i)(?<!\\w)license(?!\\w)", _, _))
    )
select javadoc, "Dangling Javadoc comment"
