public class Test {
    String[] bad = {
        """
        \u0020    leading
        """,
        """
        trailing    \u0020
        """,
        """
           \u0020    leading with space
        """,
        """
        trailing with space    \u0020    
        """,
        // Empty line
        """
        \uuuu0020
        """,
        """
        \u0020""",
        """
        \u0009
        \u000c \u000C
        """,
        // No alternative escape sequence
        """
        \u2028
        """,
    };

    String[] good = {
        // Regular string literal
        "\u0020 \n \r ",
        """
        \s \t \r \f \r
        """,
        """
        not \u0020 trailing
        """,
        // Line continuation escape is processed after incidental space was removed
        """
        continuation  \u0020 \
        """,
        """
        escaped \\u0020
        """,
        """
        not whitespace \\u00A7
        """,
    };

    String[] ignored = {
        // Don't report if on opening line of text block
        """  \u0020
        test
        """,
    };
}
