/**
 * Finds Javadoc text which contains what appears to be intended as generic type
 * parameter or argument, but is neither escaped nor is it inside a `{@code ...}`
 * or `{@literal ...}` inline tag. This will cause the Standard Doclet to consider
 * it an HTML tag which can lead to incorrect or incomplete documentation output.
 */

// TODO: Maybe remove this query in the future again; performance is not very good and
// `javadoc` tool also warns about these unknown or malformed HTML tags

import java
import lib.JavadocLib

from JavadocText javadocText, string potentialTypeParameter, int index
where
    // Make sure this is not a regular comment, see https://github.com/github/codeql/issues/3695
    exists(javadocText.getJavadoc().getCommentedElement())
    // Ignore @param tags which contain type parameter `<T>` as first argument
    and not any(ParamTag t).getChild(0) = javadocText
    // Note: Only matches deepest nested type parameters, e.g. for `List<? extends List<Number>>`
    // it would match `<Number>`, but that probably suffices
    and exists(string typeParameterOrName, string typeParameterOrArgumentPattern, string pattern |
        // E.g. <T> or <String>
        typeParameterOrName = "([A-Z]+[a-z0-9]*)+"
        and typeParameterOrArgumentPattern = (
            "("
            // Type name, or type parameter (optionally with bound)
            + typeParameterOrName + "(\\sextends\\s" + typeParameterOrName + ")?"
            + "|"
            // Wildcard (optionally with bound)
            + "\\?(\\s(extends|super)\\s" + typeParameterOrName + ")?"
            + ")"
        )
        // 'diamond' (e.g. `new List<>()`), or one or more type parameters or arguments
        and pattern = "<>|<(" + typeParameterOrArgumentPattern + ",\\s?)*" + typeParameterOrArgumentPattern + ">"
    |
       potentialTypeParameter = javadocText.getText().regexpFind(pattern, _, index)
    )
    // And does not occur within inline tag `{@code ...}` or `{@literal ...}`, or
    // `{@link ...}` or `{@linkplain ...}`; these allow parameterized types
    // Verifying that it is really part of element reference and not of link text is probably not worth it
    and not exists(JavadocParent parent, string joinedJavadocText, int textStartIndex, int inlineTagStartIndex, int inlineTagLength |
        parent = javadocText.getParent()
        and joinedJavadocText = getCompleteJavadocText(parent)
        and textStartIndex = getStartIndexInCompleteJavadocText(parent, javadocText)
        and exists(getInlineTagContent(joinedJavadocText, ["code", "literal", "link", "linkplain"], inlineTagStartIndex, inlineTagLength))
        and (textStartIndex + index) in [inlineTagStartIndex .. inlineTagStartIndex + inlineTagLength - 1]
    )
    // Ignore some common HTML tags which are written in uppercase or capitalized sometimes
    and not potentialTypeParameter.substring(1, potentialTypeParameter.length() - 1).toLowerCase() = [
        "p",
        "ul",
        "ol",
        "li",
        "pre",
        "code",
        "blockquote",
        "b",
        "i",
        "em",
        "strong",
        "a",
        "br",
        "tr",
        "dl",
        "dt",
        "dd",
        "tt",
        "h1", "h2", "h3", "h4", "h5", "h6",
        "var",
        "kbd"
    ]
select javadocText, "Contains `" + potentialTypeParameter + "` which is mistaken for an HTML tag"
