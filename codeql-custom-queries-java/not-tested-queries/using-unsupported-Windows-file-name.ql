/**
 * Finds files and folders whose name might not be a valid file name on the Windows operating system.
 * Windows has more restrictions on file names than Linux. Therefore these files and folders might
 * make it difficult or even impossible for users to work on this project on Windows.
 * 
 * @kind problem
 */

import java

predicate isReservedName(string name) {
    name = [
        // https://learn.microsoft.com/en-us/windows/win32/fileio/naming-a-file#naming-conventions
        "CON",
        "PRN",
        "AUX",
        "NUL",
        // Consider superscript numbers as well, see also https://github.com/python/cpython/blob/2016bc54a22b83d0ca9174b64257cc7bb67a0916/Lib/pathlib.py#L107-L108
        ["COM", "LPT"] + ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "¹", "²", "³"],
        // https://docs.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-createfilea#consoles 
        "CONIN$",
        "CONOUT$",
    ]
}

bindingset[s]
string trimTrailing(string s) {
    if (s.charAt(s.length() - 1) = " ") then (
        exists(int i |
            (i = 0 or s.charAt(i - 1) != " ")
            and forall(int higherIndex |
                higherIndex = [(i + 1)..(s.length() - 1)]
            |
                s.charAt(higherIndex) = " "
            )
            and result = s.prefix(i)
        )
    ) else (
        result = s
    )
}

bindingset[name]
string transformName(string name) {
    // TODO: toUpperCase() uses Unicode case conversion rules which could lead to false positives
    // because Windows only performs ASCII case conversion?
    exists(string upper | upper = name.toUpperCase() |
        if (exists(upper.indexOf("."))) then (
            // Remove 'extension', starting at the first '.'
            result = trimTrailing(upper.prefix(upper.indexOf(".", 0, 0)))
        ) else (
            // No need to trim trailing whitespace here; check below forbids trailing space
            result = upper
        )
    )
}

from Container f, string name
where
    name = f.getBaseName()
    and (
        // Reserved characters, see https://learn.microsoft.com/en-us/windows/win32/fileio/naming-a-file#naming-conventions
        exists(name.indexOf(["<", ">", ":", "\"", "/", "\\", "|", "?", "*"]))
        or exists(int c | c.toUnicode() = name.charAt(_) | c <= 31)
        or isReservedName(transformName(name))
        // Trailing period or space, see https://learn.microsoft.com/en-us/windows/win32/fileio/naming-a-file#naming-conventions
        or name.matches(["%.", "% "])
    )
select f, "Uses name '" + name + "' which is an unsupported file name under Windows"
