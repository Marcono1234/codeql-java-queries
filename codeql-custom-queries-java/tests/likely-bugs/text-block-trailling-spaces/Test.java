public class Test {
    String[] bad = {
        """
        spaces   
        second line   
        """,
        """
        tabs		
        """,
        """
        same line    """,
    };

    String[] good = {
        // Regular string literal
        "\n \r ",
        // Empty
        """
        """,
        """
        test    \s
        """,
        """
               leading
        """,
        // Line continuation escape is processed after incidental space was removed
        """
        line continuation     \
        """,
    };

    String[] ignored = {
        // Don't report if on opening line of text block
        """        
        test
        """,
    };
}
