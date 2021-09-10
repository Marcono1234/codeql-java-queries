import javadoc.lib.JavadocLib

from string javadoc, string tagName, int index, int length, string content
where
    javadoc = [
        "{@code test}",
        "{@code\t\ttabs\t\t}",
        "{@code   spaces  }",
        "{@code first second}",
        "{@code }", // Javadoc does not warn about this, but just omits it
        "{@some.:-_tag value}",
        "{@code {@code text}}", // nested one is not an inline tag
        "{@code {}{@code text}}", // nested one is not an inline tag
        "{@code {}{@code {}{@code text}}}", // nested ones are not inline tags
        "{@code {@code {first}}} {@code {@code {second}}}",
        "{{@code {}{{{}{}}}}{}}",
        "{@code \\{}}", // backslash has no effect, does not escape bracket
        "{@code \"{\"}}", // quotes have no effect, do not escape bracket
        "{@code '{'}}", // quotes have no effect, do not escape bracket
        "test {}} some text{@code more text}{}}}{",
        "some {@code tag} and another {@link test} tag",
        // Multiline
        "{@code first\nsecond\nthird}",
        "{@code first{}\nsecond\nthird}",
        "{@code\ncontent\n}",

        // No inline tags
        "",
        "some text",
        "@tag value",
        // Malformed
        "{@code test",
        "@code test}",
        "{@code test{",
        "{@code {}{{{}{}}}", // missing closing curly bracket
        "{ @code test}",
        "{@ code test}",
        "{@code}",
        "{@co#de test}",
        "{code test}",
        "{@ test}",
        "{@code\n}",
        "{@code\n\n}",
        "{@code \n}"
    ]
    and content = getInlineTagContent(javadoc, tagName, index, length)
select javadoc, javadoc.substring(index, index + length), tagName, content
