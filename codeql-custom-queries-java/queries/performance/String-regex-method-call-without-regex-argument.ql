/**
 * Finds usages of `java.lang.String` methods accepting regex patterns
 * as argument, such as `replaceAll(String, String)`, where a literal
 * regex pattern is used and a non-regex method could be used instead.
 * That alternative method might have better performance and can increase
 * readability because it avoids having to escape regex characters.
 */

import java

class StringRegexMethod extends Method {
    string alternativeMethod;

    StringRegexMethod() {
        getDeclaringType() instanceof TypeString
        and (
            hasName("matches") and alternativeMethod = "equals"
            or hasName("replaceAll") and alternativeMethod = "replace"
            // `replaceFirst` has no alternative
        )
    }

    string getAlternativeMethod() {
        result = alternativeMethod
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

from MethodAccess call, StringRegexMethod regexMethod, Expr regexArg
where
    call.getMethod() = regexMethod
    and regexArg = call.getArgument(0)
    and (
        // Uses Pattern.quote to produce literal Regex pattern
        regexArg.(MethodAccess).getMethod() instanceof PatternQuoteMethod
        or
        // Or argument does not use Regex
        exists(string stringArg |
            stringArg = regexArg.(CompileTimeConstantExpr).getStringValue()
            and not containsRegex(stringArg)
        )
    )
select call, "Argument does not use Regex; should call `" + regexMethod.getAlternativeMethod() + "(...)` instead"
