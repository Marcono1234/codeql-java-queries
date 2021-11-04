/**
 * Finds usages of `java.lang.String` methods accepting regex patterns
 * as argument, such as `replaceAll(String, String)`, where a string
 * is provided which should most likely be treated literally, but is
 * actually interpreted as special regex pattern.
 */

import java

class StringRegexMethod extends Method {
    StringRegexMethod() {
        getDeclaringType() instanceof TypeString
        and hasStringSignature([
            "matches",
            "replaceAll",
            "replaceFirst",
            "split"
        ])
    }
}

from MethodAccess regexMethodCall, StringLiteral regexArg
where
    regexMethodCall.getMethod() instanceof StringRegexMethod
    and regexArg = regexMethodCall.getArgument(0)
    // Only match single characters which have special Regex meaning, but which don't make
    // much sense on their own
    and regexArg.getValue() = [".", "|", "^", "$"]
select regexArg, "Argument is interpreted as Regex pattern with special meaning"
