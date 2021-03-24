/**
 * Finds `int` literals which are converted to `char`, but represent a
 * printable ASCII char. In this case a `char` literal should be used
 * instead. E.g.:
 * ```java
 * public boolean isLowerCase(char c) {
 *     // Should use 'a' and 'z' instead of int literals
 *     return c >= 97 && c <= 122;
 * }
 * ```
 */

import java
import semmle.code.java.Conversions

// TODO: Replace this once CodeQL has a built-in predicate, see also
// https://github.com/github/codeql/issues/3635
bindingset[codePoint]
private string getAsciiCharForCodePoint(int codePoint) {
    codePoint = 32 and result = " "
    or codePoint = 33 and result = "!"
    or codePoint = 34 and result = "\""
    or codePoint = 35 and result = "#"
    or codePoint = 36 and result = "$"
    or codePoint = 37 and result = "%"
    or codePoint = 38 and result = "&"
    or codePoint = 39 and result = "'"
    or codePoint = 40 and result = "("
    or codePoint = 41 and result = ")"
    or codePoint = 42 and result = "*"
    or codePoint = 43 and result = "+"
    or codePoint = 44 and result = ","
    or codePoint = 45 and result = "-"
    or codePoint = 46 and result = "."
    or codePoint = 47 and result = "/"
    or codePoint = 48 and result = "0"
    or codePoint = 49 and result = "1"
    or codePoint = 50 and result = "2"
    or codePoint = 51 and result = "3"
    or codePoint = 52 and result = "4"
    or codePoint = 53 and result = "5"
    or codePoint = 54 and result = "6"
    or codePoint = 55 and result = "7"
    or codePoint = 56 and result = "8"
    or codePoint = 57 and result = "9"
    or codePoint = 58 and result = ":"
    or codePoint = 59 and result = ";"
    or codePoint = 60 and result = "<"
    or codePoint = 61 and result = "="
    or codePoint = 62 and result = ">"
    or codePoint = 63 and result = "?"
    or codePoint = 64 and result = "@"
    or codePoint = 65 and result = "A"
    or codePoint = 66 and result = "B"
    or codePoint = 67 and result = "C"
    or codePoint = 68 and result = "D"
    or codePoint = 69 and result = "E"
    or codePoint = 70 and result = "F"
    or codePoint = 71 and result = "G"
    or codePoint = 72 and result = "H"
    or codePoint = 73 and result = "I"
    or codePoint = 74 and result = "J"
    or codePoint = 75 and result = "K"
    or codePoint = 76 and result = "L"
    or codePoint = 77 and result = "M"
    or codePoint = 78 and result = "N"
    or codePoint = 79 and result = "O"
    or codePoint = 80 and result = "P"
    or codePoint = 81 and result = "Q"
    or codePoint = 82 and result = "R"
    or codePoint = 83 and result = "S"
    or codePoint = 84 and result = "T"
    or codePoint = 85 and result = "U"
    or codePoint = 86 and result = "V"
    or codePoint = 87 and result = "W"
    or codePoint = 88 and result = "X"
    or codePoint = 89 and result = "Y"
    or codePoint = 90 and result = "Z"
    or codePoint = 91 and result = "["
    or codePoint = 92 and result = "\\"
    or codePoint = 93 and result = "]"
    or codePoint = 94 and result = "^"
    or codePoint = 95 and result = "_"
    or codePoint = 96 and result = "`"
    or codePoint = 97 and result = "a"
    or codePoint = 98 and result = "b"
    or codePoint = 99 and result = "c"
    or codePoint = 100 and result = "d"
    or codePoint = 101 and result = "e"
    or codePoint = 102 and result = "f"
    or codePoint = 103 and result = "g"
    or codePoint = 104 and result = "h"
    or codePoint = 105 and result = "i"
    or codePoint = 106 and result = "j"
    or codePoint = 107 and result = "k"
    or codePoint = 108 and result = "l"
    or codePoint = 109 and result = "m"
    or codePoint = 110 and result = "n"
    or codePoint = 111 and result = "o"
    or codePoint = 112 and result = "p"
    or codePoint = 113 and result = "q"
    or codePoint = 114 and result = "r"
    or codePoint = 115 and result = "s"
    or codePoint = 116 and result = "t"
    or codePoint = 117 and result = "u"
    or codePoint = 118 and result = "v"
    or codePoint = 119 and result = "w"
    or codePoint = 120 and result = "x"
    or codePoint = 121 and result = "y"
    or codePoint = 122 and result = "z"
    or codePoint = 123 and result = "{"
    or codePoint = 124 and result = "|"
    or codePoint = 125 and result = "}"
    or codePoint = 126 and result = "~"
}

from IntegerLiteral intLiteral, string asciiChar
where
    asciiChar = getAsciiCharForCodePoint(intLiteral.getIntValue())
    and intLiteral.(ConversionSite).getConversionTarget() instanceof CharacterType
select intLiteral, "Uses int literal instead of char literal for printable ASCII char '" + asciiChar + "'"
