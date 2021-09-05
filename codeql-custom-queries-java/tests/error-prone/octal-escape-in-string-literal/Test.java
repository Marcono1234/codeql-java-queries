class Test {
    String[] bad = {
        "\000",
        "\1",
        "\7",
        "\3771", // \377
        "\388", // \3
        "\\\1", // not escaped
        "\\\\\1", // not escaped
        "test\1text",
        "a\5b\6c\7d",
    };

    String[] good = {
        "\0", // don't report \0
        "\\1", // escaped
        "\\\\1", // escaped
        "\u1234",
        "\r",
    };
}