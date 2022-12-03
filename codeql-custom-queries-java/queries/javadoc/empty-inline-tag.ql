/**
 * Finds empty Javadoc inline tags for tags which normally expect a value, e.g. `{@code}`.
 * In that case the empty inline tag has no effect (except for `{@value}` on fields), so most
 * likely the inline tag in the documentation comment is empty by accident.
 * 
 * @kind problem
 */

import java

from JavadocText javadocText, string tagName, string inlineTag
where
    // Note: For some tags such as {@index} javadoc command displays an error
    (
        tagName = [
            "code",
            "index",
            "link",
            "linkplain",
            "literal",
            "summary",
            "systemProperty"
        ]
        or
        // {@value} is allowed for fields
        tagName = "value"
        and not exists(Javadoc javadoc |
            javadoc = javadocText.getJavadoc()
            and javadoc.getCommentedElement() instanceof Field
        )
    )
    and inlineTag = javadocText.getText().regexpFind("\\{@" + tagName + "\\s*\\}", _, _)
select javadocText, "Contains empty inline tag: " + inlineTag
