public class Test {
    String[] bad = {
        """
        \u000a \u000A \u000d \u000D
        """,
        // Also detect usage in the opening line
        """\u000A some text
        """,
    };

    String[] good = {
        // Regular string literal
        "\u0020 \n \r ",
        """
        \s \t \r \f \r
        """,
        """
        escaped \\u000A
        """,
    };
}