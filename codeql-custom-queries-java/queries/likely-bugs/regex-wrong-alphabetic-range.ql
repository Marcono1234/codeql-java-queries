/**
 * Finds regex patterns which include the range `[A-z]`. A regex range spans all
 * characters between the characters, therefore this range would include characters
 * such as `[` and `^` because they lie in between `Z` and `a`.
 */

import java

// TODO: Consider using `semmle.code.java.regex.RegexTreeView` library, see existing queries;
//       though this implementation here is simpler and more efficient?
// TODO: Might overlap with standard CodeQL `java/overly-large-range` query (https://github.com/github/codeql/blob/codeql-cli/v2.15.5/java/ql/src/Security/CWE/CWE-020/OverlyLargeRange.ql)

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

from RegexMethod regexMethod, MethodAccess call
where
    call.getMethod() = regexMethod
    and call.getArgument(regexMethod.regexParamIndex()).(CompileTimeConstantExpr).getStringValue().regexpMatch(
        "(?s)" // Make `.` match line breaks
        + ".*?(?:^|[^\\\\])(?:\\\\\\\\)*" // Any number of escaped back slashes -> `[` is not escaped
        + "\\[.*A-z" // Wrong alphabetic range
        + ".*"
    )
select call, "Uses wrong regex range `A-z`, use `a-zA-Z` instead"
