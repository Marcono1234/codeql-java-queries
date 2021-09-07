import lib.Strings

from string character, string codePointHex
where
    (
        character = [
            "a",
            // Invalid
            "",
            "ab"
        ]
        or exists(int codePoint | character = codePoint.toUnicode() |
            codePoint = [
                0,
                255,
                256,
                65535,
                65536,
                // Note: Cannot test surrogate code points because toUnicode() does not
                // support them, see https://github.com/github/codeql-cli-binaries/issues/80
                // Supplementary code points
                128522,
                1114111 // max code point
            ]
        )
    )
    and codePointHex = getCodePointHex(character)
select character, codePointHex
