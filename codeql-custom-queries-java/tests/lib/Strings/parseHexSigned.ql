import lib.Strings

from string s, int value
where
    s = [
        "12345678",
        "90abcdef",
        "ABCD",
        "0",
        "00000000000001", // more than 8 digits bit still within value range
        "0000FFFFFFFF", // more than 8 digits bit still within value range
        "7FFFFFFF",
        "80000000",
        "FFFFFFFF",

        // Malformed
        "",
        "0x123",
        "-12",
        "123_123",
        "  abcd",
        // Out of range
        "1FFFFFFFF",
        "00001FFFFFFFF"
    ]
    and value = parseHexSigned(s)
select s, value
