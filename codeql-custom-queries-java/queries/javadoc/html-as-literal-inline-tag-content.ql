/**
 * Finds Javadoc containing the inline tags `{@code ...}` or `{@literal ...}` which
 * have HTML code as content. These tags treat their content literally, that means
 * the created documentation will show the literal HTML code as text. If that is not
 * desired a workaround can be to use `<code> ... </code>` instead of the
 * `{@code ...}` tag.
 */

import java
import lib.JavadocLib

bindingset[text]
string getOpeningHtmlTag(string text, string tagName, int index) {
    result = text.regexpFind("<[a-zA-Z0-9]+>", _, index)
    and tagName = result.substring(1, result.length() - 1)
}

bindingset[text]
string getClosingHtmlTag(string text, string tagName, int index) {
    result = text.regexpFind("</[a-zA-Z0-9]+>", _, index)
    and tagName = result.substring(2, result.length() - 1)
}

// Does not consider multiline `{@code ...}` because it might intentionally contain HTML

from JavadocText javadocText, string inlineTag, string tagContent, string htmlContent
where
    // Make sure this is not a regular comment, see https://github.com/github/codeql/issues/3695
    exists(javadocText.getJavadoc().getCommentedElement())
    and exists(string text, int index, int length |
        text = javadocText.getText()
        and tagContent = getInlineTagContent(
            text,
            ["code", "literal"],
            index,
            length
        )
        and inlineTag = text.substring(index, index + length)
    )
    and (
        htmlContent = tagContent.regexpFind([
            // Digit count limits are to cover at most max code point U+10FFFF
            "&#x[0-9a-fA-F]{1,6};", // hexadecimal reference
            "&#[0-9]{1,7};", // decimal reference
            // Assume here at most 10 chars to reduce false positives
            "&[a-zA-Z]{1,10};", // named reference
            "<[a-zA-Z]+\\s?/>" // self closing HTML tag
        ], _, _)
        // Or opening HTML tag (and to reduce false positives require closing HTML tag)
        or exists(int index, string tagName, int closingIndex |
            htmlContent = getOpeningHtmlTag(tagContent, tagName, index)
            and exists(getClosingHtmlTag(tagContent, tagName, closingIndex))
            and closingIndex > index
        )
    )
    // Often when tag content consists only of the HTML content it is done on purpose
    and not tagContent = [
        htmlContent,
        "\"" + htmlContent + "\"",
        "'" + htmlContent + "'"
    ]
select javadocText, "Contains HTML `" + htmlContent + "` in literal inline tag `" + inlineTag + "`"
