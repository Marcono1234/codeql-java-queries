/**
 * Finds calls on String which appear to perform case insensitive comparison
 * by first converting the String using `toLowerCase` or `toUpperCase`.
 * Such calls should be replaced with the special case insensitive String
 * methods which won't create an intermediate String, and therefore will
 * perform better and might prevent denial of service attacks possible
 * due to Unicode special casing rules.
 */

import java

class StringCasingMethod extends Method {
    StringCasingMethod() {
        getDeclaringType() instanceof TypeString
        and hasName(["toLowerCase", "toUpperCase"])
    }
}

class StringCheckingCallWithAlternative extends MethodAccess {
    string alternative;
    
    StringCheckingCallWithAlternative() {
        exists(Method m |
            m = getMethod()
            and m.getDeclaringType() instanceof TypeString
            and getQualifier().(MethodAccess).getMethod() instanceof StringCasingMethod
        |
            m instanceof EqualsMethod and alternative = "equalsIgnoreCase"
            or m.hasStringSignature("compareTo(String)") and alternative = "compareToIgnoreCase"
            or (
                m.hasStringSignature("contentEquals(CharSequence)")
                // contentEquals can only be replaced when called with String
                and getArgument(0).getType() instanceof TypeString
                and alternative = "equalsIgnoreCase"
            )
        )
    }
    
    string getAlternative() {
        result = alternative
    }
}

from StringCheckingCallWithAlternative call
select call, "Should use " + call.getAlternative() + " instead of manually converting case"
