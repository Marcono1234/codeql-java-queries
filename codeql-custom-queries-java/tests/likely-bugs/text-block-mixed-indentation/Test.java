public class Test {
    String[] bad = {
        """
    	mixed same line
	    mixed same line2
        """,
        """
        test
	    """, // mixed on last line
        """
        spaces
		tabs
        """,
        """
        spaces
        spaces
		tabs
		tabs
        """,
        """
        spaces
		""", // tabs
        """
        spaces, line continuation \
		tabs
        """,
    };

    String[] good = {
        // Regular string literal
        "\n \r 	 ",
        // Empty
        """
        """,
        """
        trailing mixed   	  
        """,
        """
        text
no indentation
        """,
        """
        line continuation     \
        """,
        // Mixed trailing on opening line
        """		    
        """,

    };
}
