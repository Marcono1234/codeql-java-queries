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

class PatternQuoteMethod extends Method {
    PatternQuoteMethod() {
        getDeclaringType().hasQualifiedName("java.util.regex", "Pattern")
        and hasName("quote")
    }
}

from MethodAccess call, Expr toReplaceArg
where
    call.getMethod() instanceof ReplaceAllMethod
    and toReplaceArg = call.getArgument(0)
    and (
        // Uses Pattern.quote to produce literal Regex pattern
        toReplaceArg.(MethodAccess).getMethod() instanceof PatternQuoteMethod
        or
        // Or toReplace string does not use Regex
        exists(string toReplace |
            toReplace = toReplaceArg.(CompileTimeConstantExpr).getStringValue()
            and not containsRegex(toReplace)
        )
    )
select call, "String to replace does not use Regex; should use `replace(...)` instead"
