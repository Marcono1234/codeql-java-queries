class Test {
    String[] bad = {
        "test\stext",
        "\s test \s",
        "\\\s not escaped",
    };

    String[] good = {
        "test text",
        "\\s escaped backslash",
        """
        text block \s
        """,
    };
}