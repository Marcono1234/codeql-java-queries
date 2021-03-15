/**
 * Finds Javadoc text which appears to be using backticks (`\``) for
 * formatting text as code. The Standard Doclet does not treat backticks
 * in a special way and therefore they appear in the javadoc output
 * without applying any formatting.
 * The `{@code ...}` inline tag should be used instead.
 */

import java

JavadocText getPredecessor(JavadocText text) {
    result.getParent() = text.getParent()
    and result.getIndex() = text.getIndex() - 1
}

predicate isInCodeBlock(JavadocText text) {
    // Concat all predecessors and check for `<pre>` without closing `</pre>`
    concat(JavadocText predecessor | predecessor = getPredecessor+(text) | predecessor.getText() order by predecessor.getIndex() asc)
        // `(?i)` to match `pre` case-insensitively
        .regexpMatch("(?i).*<pre>(?:(?!<\\/pre>).)*")
}

from Javadoc parent, JavadocText text
where
    // Javadoc also matches regular comment, so make sure it is actually javadoc
    exists (parent.getCommentedElement())
    and (
        // If commented element is modifiable, make sure it is public or protected
        // since javadoc is normally only generated for those
        not parent.getCommentedElement() instanceof Modifiable
        or parent.getCommentedElement().(Modifiable).isPublic()
        or parent.getCommentedElement().(Modifiable).isProtected()
    )
    // Ignore if javadoc is used in test class since javadoc is normally not generated
    // for those
    and not exists (TestClass testClass |
        testClass.getCompilationUnit() = parent.getCommentedElement().getCompilationUnit()
    )
    // Ideally would match text inside JavadocTag as well, however that is currently not
    // reliably possible, see https://github.com/github/codeql/issues/3825
    and text.getParent() = parent
    // Ignore if in code block, there it might be used as part of a comment, e.g.: // if `var` is null
    and not isInCodeBlock(text)
    and text.getText().matches("%`_%`%")
select text
