import lib.Strings

from string s, boolean matches
where
    s = [
        " ", // space (also part of \p{Zs})
        "\t",
        "\n",
        "\r",
        "\t  \t \n",
        "", // \f (U+000C)
        " ", // \p{Zl}: U+2028
        " ", // \p{Zp}: U+2029

        // Not matching
        "",
        "a  ",
        "  a",
        " a ",
        // Excluded
        " ", // U+00A0
        " ", // U+2007
        " " // U+202F
    ]
    and if (consistsOnlyOfJavaWhitespaces(s)) then matches = true
    else matches = false
select s, matches
