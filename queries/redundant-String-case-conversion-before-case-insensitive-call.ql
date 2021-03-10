/**
 * Finds String case conversion calls whose result is then compared using
 * a case insensitive method. This most likely renders the case conversion
 * redundant.
 */

import java

class StringCasingMethod extends Method {
    StringCasingMethod() {
        getDeclaringType() instanceof TypeString
        and hasName(["toLowerCase", "toUpperCase"])
    }
}

class StringCaseInsensitiveMethod extends Method {
    StringCaseInsensitiveMethod() {
        getDeclaringType() instanceof TypeString
        and hasName(["compareToIgnoreCase", "equalsIgnoreCase"])
    }
}

from MethodAccess casingCall, MethodAccess caseInsensitiveCall
where
    casingCall.getMethod() instanceof StringCasingMethod
    and (
        caseInsensitiveCall.getQualifier() = casingCall
        or caseInsensitiveCall.getArgument(0) = casingCall
    )
    and caseInsensitiveCall.getMethod() instanceof StringCaseInsensitiveMethod
select casingCall, "Unnecessary case conversion before $@ case insensitive call", caseInsensitiveCall, "this"
