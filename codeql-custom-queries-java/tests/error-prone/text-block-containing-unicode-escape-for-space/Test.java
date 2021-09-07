public class Test {
    String[] bad = {
        """
        \u0020 \u0009 \u000c \u000C
        """,
        """
        \uuuu0020
        """,
        // On opening line
        """   \u0020
        """,
    };

    String[] good = {
        // Regular string literal
        "\u0020 \n \r ",
        """
        \s \t \r \f \r
        """,
        """
        escaped \\u0020
        """,
    };

    String[] ignored = {
        // Line terminators are covered by separate query
        """
        \u000a \u000A \u000d \u000D
        """,
    };
}