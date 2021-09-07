import lib.Strings

from int i, string hex
where
    i = [
        0,
        1,
        -1,
        25,
        255,
        2147483647,
        -2147483648
    ]
    and hex = unsignedToHex(i)
select i, hex
