/**
 * Finds usage of one of the Apache Commons Lang `StringUtils` methods which takes a
 * `String` or `CharSequence` parameter representing a set of characters, but where
 * the provided argument appears to be regular text.
 * 
 * For example consider this usage of `StringUtils.split(String, String)`:
 * ```java
 * StringUtils.split("sand and land", " and ")
 * ```
 * The author might have wanted to split the text between the separator `" and "`, but
 * what this code actually does it splitting the text at ` `, `a`, `n` and `d`, resulting in
 * `["s", "l"]`.
 */

import java

class ClassStringUtils extends Class {
    ClassStringUtils() {
        hasQualifiedName(["org.apache.commons.lang", "org.apache.commons.lang3"], "StringUtils")
    }
}

/**
 * Method where a `String` or `CharSequence` parameter represents a set of characters.
 */
class StringAsCharSetMethod extends Method {
    int paramIndex;
    
    StringAsCharSetMethod() {
        getDeclaringType() instanceof ClassStringUtils
        and exists(string sig |
            sig = getStringSignature()
        |
            sig = [
                "containsAny(String, String)",
                "containsAny(CharSequence, CharSequence)", // Lang 3
                "containsNone(String, String)",
                "containsNone(CharSequence, String)", // Lang 3
                "containsOnly(String, String)",
                "containsOnly(CharSequence, String)", // Lang 3
                "indexOfAny(String, String)",
                "indexOfAny(CharSequence, String)", // Lang 3
                "indexOfAnyBut(String, String)",
                "indexOfAnyBut(CharSequence, CharSequence)", // Lang 3
                "reverseDelimitedString(String, String)", // Deprecated in Commons Lang 2; does not exist in Commons Lang 3
                "strip(String, String)",
                "stripAll(String[], String)",
                "stripEnd(String, String)",
                "stripStart(String, String)",
            ]
            and paramIndex = 1
            or
            sig = "replaceChars(String, String, String)"
            and paramIndex = [1, 2]
            or
            sig = [
                "split(String, String)",
                "split(String, String, int)",
            ]
            and paramIndex = [1, 2]
            or
            sig = [
                "splitPreserveAllTokens(String, String)",
                "splitPreserveAllTokens(String, String, int)",
            ]
            and paramIndex = [1, 2]
        )
    }
    
    /**
     * 0-based index of one of the parameters representing a set of characters.
     */
    int getSetOfCharsParamIndex() {
        result = paramIndex
    }
}

from MethodAccess methodCall, StringAsCharSetMethod method, CompileTimeConstantExpr stringArg, string stringValue
where
    method = methodCall.getMethod()
    and stringArg = methodCall.getArgument(method.getSetOfCharsParamIndex())
    and stringValue = stringArg.getStringValue()
    // And string looks like regular text (instead of set of characters)
    and exists(stringValue.regexpFind("[a-zA-Z]{3,}", _, _))
select methodCall, "Uses the text '$@' as set of characters", stringArg, stringValue
