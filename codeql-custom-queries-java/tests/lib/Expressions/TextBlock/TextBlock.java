package TextBlock;

class TextBlock {
    String[] textBlocks = {
        """
        """,
        """
        test
        """,
        """
        test""",
        """
        first
        second""",
        """

        """,
        """
        continuation \
        next
        """,
        """
        escaped \\
        next
        """,
        """
""",
    };

    String notATextBlock = "\r\n";
}