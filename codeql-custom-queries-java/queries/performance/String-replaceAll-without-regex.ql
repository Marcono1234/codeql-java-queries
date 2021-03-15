/**
 * Finds usages of `String.replaceAll(String, String)` where
 * `replace(CharSequence, CharSequence)` or `replace(char, char)` could
 * be used instead.
 *
 * `replaceAll` uses regex to perform the match which can unnecessarily
 * decrease the performance if no regex features are used. And it might
 * also reduce readability if certain characters have to be escaped
 * because they would have a special meaning in the regex otherwise.
 */

import java

class ReplaceAllMethod extends Method {
    ReplaceAllMethod() {
        getDeclaringType().hasQualifiedName("java.lang", "String")
        and hasStringSignature("replaceAll(String, String)")
    }
}

bindingset[s]
predicate containsRegex(string s) {
    s.regexpMatch(
        "(?s)" // Make `.` match line breaks
        + ".*?(?:^|[^\\\\])(?:\\\\\\\\)*" // Any number of escaped back slashes
        + "(?:"
            + "[\\[\\]()|.*+?^${}]" // Group, quantifier, ...
            + "|" // OR
            // Backslash followed by character class or escape sequence, see java.util.regex.Pattern
            + "\\\\(?:x\\{|[NcdDhHsSvVwWpPbBAGzZRXQE])"
        + ").*"
    )
}

from MethodAccess call, string toReplace
where
    call.getMethod() instanceof ReplaceAllMethod
    and toReplace = call.getArgument(0).(CompileTimeConstantExpr).getStringValue()
    and not containsRegex(toReplace)
select call, toReplace
