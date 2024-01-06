/**
 * Finds regex patterns which use misleading character classes (`[...]`).
 */

import java

// TODO: Consider using `semmle.code.java.regex.RegexTreeView` library, see existing queries

// TODO: These are already declared in `regex-wrong-alphabetic-range.ql`, reduce code duplication
abstract class RegexMethod extends Method {
    abstract int regexParamIndex();
}

class TypePattern extends Class {
    TypePattern() {
        hasQualifiedName("java.util.regex", "Pattern")
    }
}

class PatternRegexMethod extends RegexMethod {
    PatternRegexMethod() {
        getDeclaringType() instanceof TypePattern
        and hasName(["compile", "matches"])
    }
    
    override
    int regexParamIndex() {
        result = 0
    }
}

class StringRegexMethod extends RegexMethod {
    StringRegexMethod() {
        getDeclaringType() instanceof TypeString
        and hasName(["matches", "replaceAll", "replaceFirst", "split"])
    }
    
    override
    int regexParamIndex() {
        result = 0
    }
}

bindingset[regex]
private int findCharacterClassStart(string regex, int start) {
    result >= start and start = [0 .. regex.length() - 1]
    and exists(int tempStart |
        exists(regex.regexpFind(
            // Allow optional `&&` prefix for intersection, but not if prefixed with `-`
            // TODO: `-` prefix is only a problem if something other than not-escaped `[` or `]` is in front
            //       E.g.: `[-&&[#-?]]` (matches only `-`), `[[a]-&&[a-z]]` (matches only `a`)
            //       However: E.g. `[^-&&[a]]` (matches `^-&`, `&`, `a`)
            // TODO: Intersection prefix `&&` should only be considered for nested character classes;
            //       for top level character classes it is not part of the character class
            "(?<!\\\\)(?:\\\\\\\\)*(?:(?<!-)&&)?\\[", // unescaped `[`
            _,
            tempStart
        ))
        and result = min(regex.indexOf(["&", "["], 0, tempStart)) // Remove leading backslashes
    )
}

/**
 * Gets a potential index (inclusive) of the closing square bracket of a character
 * class. The index will be >= `start`.
 */
bindingset[regex]
private int findPotentialCharacterClassEnd(string regex, int start) {
    result >= start and start = [0 .. regex.length() - 1]
    and exists(int tempEnd |
        exists(regex.regexpFind(
            "(?<!\\\\)(?:\\\\\\\\)*\\]", // unescaped `]`
            _,
            tempEnd
        ))
        and result = regex.indexOf("]", 0, tempEnd) // Remove leading backslashes
    )
}

/**
 * Gets the index (inclusive) of the closing square bracket of a character
 * class whose opening square bracket is at an index < `start`.
 */
bindingset[regex]
private int findCharacterClassEnd(string regex, int start) {
    exists(int startCount |
        startCount = count(findCharacterClassStart(regex, start))
    |
        startCount = 0 and result = min(findPotentialCharacterClassEnd(regex, start))
        or result = min(any(int rankIndex, int endIndex |
            // + 1 because start for which the end is searched is not part of the searched string
            endIndex = rank[rankIndex + 1](findPotentialCharacterClassEnd(regex, start))
            and (
                // End is before all of the starts (rank starts at 1)
                rankIndex = 0
                // End is after nested start
                or endIndex > rank[rankIndex](findCharacterClassStart(regex, start))
            )
            and (
               // There are no further starts
               rankIndex = startCount
               /*
                * Or end index is in front of them, e.g.:
                * [[]]] ... [
                *     ^ will match this
                */
               or endIndex < rank[rankIndex + 1](findCharacterClassStart(regex, start))
            )
        |
            endIndex
        ))
    )
}

/**
 * Holds if `index` is part of any character class (including opening and closing
 * brackets and intersection prefix `&&`) whose start index is >= `start`.
 */
bindingset[regex, index]
predicate isPartOfCharacterClass(string regex, int start, int index) {
    exists(int characterClassStart |
        characterClassStart <= index
        and characterClassStart = findCharacterClassStart(regex, start)
        and findCharacterClassEnd(regex, characterClassStart + 1) >= index
    )
}

/**
 * Gets the content of a character class (including nested character classes) whose
 * content starts at index `characterClassContentStart` and the character class itself
 * starts at index >= `start`.
 * The content is the substring between opening and closing square bracket.
 */
bindingset[regex]
string getACharacterClassContent(string regex, int start, int characterClassContentStart) {
    exists(int tempStart |
        tempStart = findCharacterClassStart(regex, start)
    |
        // Remove intersection prefix, if any
        // Exclude negation char `^`, if any
        characterClassContentStart = max(regex.indexOf(["[", "^"], 0, tempStart)) + 1
        and result = regex.substring(characterClassContentStart, findCharacterClassEnd(regex, characterClassContentStart))
    )
}

bindingset[s, startIndex, length]
private string getPreview(string s, int startIndex, int length) {
    exists(int endIndex | endIndex = startIndex + length |
       // Include up to 5 more characters for preview
       result = s.substring(max([startIndex - 5, 0]), min([endIndex + 5, s.length()]))
    )
}

from RegexMethod regexMethod, MethodAccess call, string regex, int contentStart, string content, string misleadingStr, int misleadingIndex, string message
where
    call.getMethod() = regexMethod
    and regex = call.getArgument(regexMethod.regexParamIndex()).(CompileTimeConstantExpr).getStringValue()
    and content = getACharacterClassContent(regex, _, contentStart)
    and (
        (
            // Intersection at beginning acts like union; `&&` prefix can be omitted
            message = "Misleading intersection at beginning of character class"
            and misleadingStr = "&&["
            and content.indexOf(misleadingStr) = 0
            and misleadingIndex = contentStart
        )
        or (
            // `\&&[` looks very close to intersection `&&[`; should escape both ampersands for clarity
            message = "Misleading escaped intersection characters"
            and misleadingStr = "\\&&["
            and misleadingIndex = contentStart + content.indexOf(misleadingStr)
            // Ignore if `&&[` is not actually escaped (i.e. backslash is escaped) and
            // is part of nested character class
            // + 1 to not check for leading `\`
            and not isPartOfCharacterClass(regex, misleadingIndex + 1, misleadingIndex + 1)
        )
        or (
            // `-&&[` looks very close to intersection `&&[`; should escape second ampersand for clarity
            message = "Misleading escaped intersection characters"
            and misleadingStr = "-&&["
            and misleadingIndex = contentStart + content.indexOf(misleadingStr)
        )
        or exists(int misleadingIndexTemp, string misleadingStrTemp |
            // Not escaped hyphen can be misleading, e.g. `[#--a]` should be written as `[#-\-a]`
            // And they can be error prone when char is added later, e.g. `[.-]`
            // adding `_` (`[.-_]`) would create a range `.` to `_` which is likely not intended
            message = "Misleading not escaped hyphen"
            and misleadingStrTemp = content.regexpFind(
                // TODO: Also consider case where `-` is adjacent to nested, e.g. `[[a]-[b]]`
                "(?:"
                    + "^-(?!$)" // hyphen at beginning (and not end of class behind)
                + "|"
                    + "(?<!^)(?<!\\\\)(?:\\\\\\\\)*-$" // not escaped hyphen at end (and not start of class in front)
                + "|"
                    // Cannot easily tell whether this is `start-` or `-end` (with start and end being `-`)
                    // Therefore misleadingIndex will be incorrect for case `-end` where `end`
                    // should be escaped
                    + "(?<!\\\\)(?:\\\\\\\\)*--" // not escaped double hyphen
                + ")",
                _,
                misleadingIndexTemp
            )
            and misleadingIndex = contentStart + misleadingStrTemp.indexOf("-", 0, 0) // remove leading backslashes
            and misleadingStr = misleadingStrTemp.suffix(misleadingIndex - contentStart)
            // Ignore if part of nested character class (that one will report it itself)
            and not isPartOfCharacterClass(regex, misleadingIndex, misleadingIndex)
        )
        or exists(string symbolPattern, int misleadingIndexTemp, string misleadingStrTemp |
            symbolPattern = "[ !\"#$%&'()*+,./:;<=>?@\\[\\]^`{|}~]"
        |
            message = "Range with symbol"
            and misleadingStrTemp = content.regexpFind(
                "(?:"
                    + "(?<!\\\\|^)-" + symbolPattern // range ending with symbol
                + "|"
                    + symbolPattern + "-(?!$)" // range starting with symbol
                + "|"
                    + "(?<!\\\\)(?:\\\\\\\\)+-(?!$)" // range with backslash
                + ")",
                _,
                misleadingIndexTemp
            )
            and misleadingIndex = contentStart + misleadingStrTemp.indexOf(min(["-", "\\-"]), 0, 0) // only keep at most one non-escaped backslash
            and misleadingStr = misleadingStrTemp.suffix(misleadingIndex - contentStart)
        )
    )
// TODO: Sometimes reports wrong index
select call, message + " at (0-based) index " + misleadingIndex + " in regex: " + getPreview(regex, misleadingIndex, misleadingStr.length())
