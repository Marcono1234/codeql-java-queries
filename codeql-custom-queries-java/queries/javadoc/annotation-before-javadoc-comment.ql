/**
 * Finds Javadoc comments which might be ignored by the `javadoc` tool because an annotation on
 * the documentated element is placed before the comment. For example:
 * ```java
 * @SuppressWarnings("unchecked")
 * /**
 *  * Does something
 *  * /
 * public void doSomething() {
 *     ...
 * }
 * ```
 * Instead all annotations should be placed between the Javadoc comment and the annotated element:
 * ```java
 * /**
 *  * Does something
 *  * /
 * @SuppressWarnings("unchecked")
 * public void doSomething() {
 *     ...
 * }
 * ```
 * 
 * See [JDK-8294007](https://bugs.openjdk.org/browse/JDK-8294007) describing this issue.
 * 
 * @kind problem
 */

// Has overlap with dangling-javadoc-comment.ql, but is much more precise

import java

from Javadoc javadoc, Documentable documentable, Annotation annotation
where
    javadoc.getFile() = documentable.getFile()
    // Javadoc ends right above documentable
    and javadoc.getLocation().getEndLine() + 1 = documentable.getLocation().getStartLine()
    and annotation.getAnnotatedElement() = documentable
    // Annotation on documentable is in front of Javadoc comment
    and annotation.getLocation().getEndLine() < javadoc.getLocation().getStartLine()
    // Javadoc also matches regular block and EOL comments; ignore those
    and not isNormalComment(javadoc)
    and not exists(javadoc.getCommentedElement())
    // Ignore documentated `package-info.java`, does not seem to be covered by `getCommentedElement()`
    and not javadoc.getFile().(CompilationUnit).hasName("package-info")
select javadoc, "Comment might be ignored due to $@ annotation before the comment", annotation, "this"
