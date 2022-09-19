/**
 * Finds Javadoc comments where the first sentence might not be correctly detected. Javadoc uses
 * the fist sentence for types in the package overview and for members in the fields and methods
 * list to provide a short summary. By default the first period followed by a space or line break
 * is considered the end of the first sentence. This can in some cases lead to undesired results,
 * for example for `A number, e.g. the integer 5.` the substring `A number, e.g.` would erroneously
 * be considered the first sentence.
 * 
 * A solution to this is to place the erroneously detected period (and surrounding words) in
 * `{@literal ...}`. Starting with Java 10 the proper solution is to use the inline tag
 * `{@summary ...}` to explicitly surround the section which should be displayed as summary.
 * 
 * The automatic detection of the sentence end can be adjusted with the `-breakiterator`
 * `javadoc` option, however that detection mode may also produce incorrect results.
 * 
 * @kind problem
 */

import java

// Note: CodeQL represents each line as separate JavadocText
from Javadoc javadoc, JavadocParent parent, JavadocText firstJavadocText, string fullText, string firstSentence
where
    javadoc = firstJavadocText.getJavadoc()
    // Javadoc also matches regular comments, ignore those
    and exists(javadoc.getCommentedElement())
    and (
        parent = javadoc
        // @deprecated tag also has a summary
        or parent.(JavadocTag).getTagName() = "@deprecated"
    )
    and parent = firstJavadocText.getParent()
    // Make sure firstJavadocText is really the first text
    and not exists(JavadocText previousText |
        previousText.getParent() = parent
        and previousText.getIndex() < firstJavadocText.getIndex()
    )
    and fullText = concat(JavadocText javadocText |
        javadocText.getParent() = parent
        // Work around multiline text not properly recorded as children of block tag, see https://github.com/github/codeql/issues/3825
        // Ignore if there is a block tag in front of the text
        and not exists(JavadocTag tag |
            tag.getParent() = parent
            and tag.getIndex() < javadocText.getIndex()
        )
    |
        javadocText.getText(), " "
        order by javadocText.getIndex() asc
    )
    and exists(int endIndex |
        // See https://docs.oracle.com/en/java/javase/17/docs/specs/man/javadoc.html, -breakiterator description
        endIndex = fullText.indexOf(". ", 0, 0)
        and firstSentence = fullText.prefix(endIndex + 1)
    |
        exists(fullText.regexpFind(
            [
                "(?<=\\W[a-zA-Z])", // single letter in front of `.`
                "\\. [a-z]", // lower case letter after period
            ],
            _,
            endIndex
        ))
    )
    // Ignore usage of {@summary }
    and not firstSentence.matches("%{@summary %")
    // Ignore usage of (potential) HTML block tag, it separates the first sentence as well
    and not firstSentence.regexpMatch(".*</?([a-z]{1,4}|[A-Z]{1,4})>.*")
select firstJavadocText, "Javadoc might incorrectly detect the following as first sentence: " + firstSentence
