/**
 * Finds usage of the `{@literal ...}` Javadoc inline tag for content which cannot be
 * misinterpreted. The `@literal` tag prevents interpretation of its content as HTML
 * or nested Javadoc tag, but it does not add any special formatting (such as code formatting).
 * Therefore using the tag for content which does not contain any HTML or Javadoc tag
 * characters is redundant.
 * 
 * See [documentation for `{@literal}`](https://docs.oracle.com/en/java/javase/17/docs/specs/javadoc/doc-comment-spec.html#literal).
 */

import java
import lib.JavadocLib

from JavadocText javadocText, string tagContent
where
    // Make sure this is not a regular comment, see https://github.com/github/codeql/issues/3695
    exists(javadocText.getJavadoc().getCommentedElement())
    and tagContent = getInlineTagContent(javadocText.getText(), "literal", _, _)
    // Content does not contain HTML or nested Javadoc tag
    and tagContent.regexpMatch("(?s)[^<>&{}@]*")
select javadocText, "@literal inline tag is redundant for content: " + tagContent
