/**
 * Finds Javadoc text which is most likely a malformed inline tag.
 * Inline tags have the format `{@tagName ...}`; placing the `@` in front of the
 * opening curly bracket, or omitting it will cause the tag to not be displayed
 * correctly.
 */

import java

predicate isInsideHtmlCodeBlock(JavadocText javadocText) {
    // Note: Each JavadocText is a separate line, see https://github.com/github/codeql/issues/3696
    exists(JavadocParent parent, JavadocText startingText |
        parent = javadocText.getParent()
        and startingText.getParent() = parent
        and startingText.getIndex() < javadocText.getIndex()
        and exists(startingText.getText().indexOf(["<pre>", "<PRE>"]))
        // And there is no line which closes the code block before
        and not exists(JavadocText closingText |
            closingText.getParent() = parent
            and closingText.getIndex() > startingText.getIndex()
            and closingText.getIndex() < javadocText.getIndex()
            and exists(closingText.getText().indexOf(["</pre>", "</PRE>"]))
        )
    )
}

from JavadocText javadocText, string text, string malformedTag
where
    // Make sure this is not a regular comment, see https://github.com/github/codeql/issues/3695
    exists(javadocText.getJavadoc().getCommentedElement())
    and text = javadocText.getText()
    and exists(string malformedTagPattern, string tagName |
        // Look for opening curly bracket without '@'; match group 1 is the tag name
        malformedTagPattern = "\\{ ?([a-zA-Z]+)[ }]"
        and malformedTag = text.regexpFind(malformedTagPattern, _, _)
        and tagName = malformedTag.regexpCapture(malformedTagPattern, 1)
        // Reduce false positives by only checking for known tag names
        // see https://docs.oracle.com/en/java/javase/17/docs/specs/javadoc/doc-comment-spec.html#standard-tags
        and tagName = [
            "code",
            "docRoot",
            "index",
            "inheritDoc",
            "link",
            "linkplain",
            "literal",
            "return", // also exists as inline tag since JDK 16
            "summary",
            "systemProperty",
            "value"
        ]
    )
    // Ignore false positives picked up in code blocks, e.g. { return 1; }
    and not isInsideHtmlCodeBlock(javadocText)
select javadocText, "Contains malformed inline tag: " + malformedTag
