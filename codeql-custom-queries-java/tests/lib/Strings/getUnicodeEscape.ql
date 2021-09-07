import lib.Strings

from string s, string escape, int index, string hex
where
    s = [
        "\\u0123",
        "\\u4567",
        "\\u89ab",
        "\\ucdef",
        "\\uABCD",
        "\\uuuuu1234",
        "test\\u1234test",
        "1234\\u123456",
        "abcd\\uabcdef",
        "\\u1234\\uabcd",

        // No escapes
        "",
        "\\u000", // incomplete
        "\\U0000", // uppercase U
        // Escaped
        "\\\\u0000",
        "\n \\\\u0000"
    ]
    and escape = getUnicodeEscape(s, index, hex)
select s, escape, index, hex
