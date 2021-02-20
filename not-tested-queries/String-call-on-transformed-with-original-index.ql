/**
 * Finds method calls on a String, which was transformed in some way, but
 * where the call is using an index or length value which was obtained from
 * the String before it was transformed. This can lead to an
 * `IndexOutOfBoundsException` being thrown, or can cause incorrect behavior.
 * E.g.:
 * ```
 * public static String normalize(String id) {
 *     int length = id.length();
 *     // Even for ROOT locale this might result in length changes for some
 *     // characters, see https://unicode.org/Public/UNIDATA/SpecialCasing.txt
 *     String normalized = id.toLowerCase(Locale.ROOT);
 *     if (normalized.endsWith("#")) {
 *         // Can cause incorrect behavior when `toLowerCase` changed length
 *         // because `length` still refers to original length
 *         normalized = normalized.substring(0, length - 1);
 *     }
 *     return normalized;
 * }
 * ```
 */

import java
import semmle.code.java.dataflow.DataFlow

/**
 * String method which in some way transforms the original String.
 */
private class StringTransformingMethod extends Method {
    StringTransformingMethod() {
        getDeclaringType() instanceof TypeString
        // Only consider methods which keep the original "meaning" of the
        // String, e.g. exclude `format(...)` which transforms formatting template
        // to formatted String
        and (
            hasName([
                "replaceAll", "replaceFirst",
                "strip", "stripIndent", "stripLeading", "stripTrailing",
                // For some chars this changes the result size, see
                // https://unicode.org/Public/UNIDATA/SpecialCasing.txt
                "toLowerCase", "toUpperCase",
                "transform",
                "translateEscapes",
                "trim"
                
            ])
            // Do not consider `replace(char, char)` because the length
            // will not change
            or hasStringSignature("replace(CharSequence, CharSequence)")
        )
    }
}

/**
 * String method which returns an index within the String, or the length
 * of the String. Covers both `char` and code point methods.
 */
class StringIndexReturningMethod extends Method {
    StringIndexReturningMethod() {
        // Also consider supertypes of String, namely CharSequence
        any(TypeString s).getASourceSupertype*() = getDeclaringType()
        and hasName([
            "codePointCount",
            "indexOf",
            "lastIndexOf",
            "length",
            "offsetByCodePoints"
        ])
    }
}

class StringIndexAcceptingMethod extends Method {
    private int indexParamIndex;
    
    StringIndexAcceptingMethod() {
        // Also consider supertypes of String, namely CharSequence
        any(TypeString s).getASourceSupertype*() = getDeclaringType()
        and (
            hasName(["charAt", "codePointAt", "codePointBefore"]) and indexParamIndex = 0
            or hasName("codePointCount") and indexParamIndex = [0, 1]
            or hasStringSignature("getBytes(int, int, byte[], int)") and indexParamIndex = [0, 1]
            or hasName("getChars") and indexParamIndex = [0, 1]
            or hasName(["indexOf", "lastIndexOf"]) and indexParamIndex = 1
            or hasName("offsetByCodePoints") and indexParamIndex = [0, 1] // also consider `codePointOffset` param
            or hasStringSignature("regionMatches(boolean, int, String, int, int)") and indexParamIndex = [1, 4] // also consider `len` param
            or hasStringSignature("regionMatches(int, String, int, int)") and indexParamIndex = [0, 3] // also consider `len` param
            or hasName("startsWith") and indexParamIndex = 1
            or hasName(["subSequence", "substring"]) and indexParamIndex = [0, 1]
        )
    }
    
    /** Gets the index of the parameter representing a String index (or length) */
    int getIndexParamIndex() {
        result = indexParamIndex
    }
}

class ExternalStringIndexAcceptingMethod extends Method {
    private int stringParamIndex;
    private int stringIndexParamIndex;
    
    ExternalStringIndexAcceptingMethod() {
        // Also consider supertypes of String, namely CharSequence
        any(TypeString s).getASourceSupertype*() = getDeclaringType()
        and (
            hasStringSignature("regionMatches(boolean, int, String, int, int)") and stringParamIndex = 2 and stringIndexParamIndex = [3, 4] // also consider `len` param
            or hasStringSignature("regionMatches(int, String, int, int)") and stringParamIndex = 1 and stringIndexParamIndex = [2, 3] // also consider `len` param
        )
    }
    
    /** Gets the index of the parameter representing an external String. */
    int getExternalStringParamIndex() {
        result = stringParamIndex
    }
    
    /**
     * Gets the index of the parameter representing a String index (or length) of
     * the external String.
     */
    int getExternalStringIndexParamIndex() {
        result = stringIndexParamIndex
    }
}

from Expr stringExpr, MethodAccess indexReturningCall, MethodAccess transformingCall, MethodAccess indexUsage,
    DataFlow::Node indexSink, DataFlow::Node transformedStringSink
where
    stringExpr.getType() instanceof TypeString
    and indexReturningCall.getMethod() instanceof StringIndexReturningMethod
    and transformingCall.getMethod() instanceof StringTransformingMethod
    // Flow from mutual stringExpr to indexReturningCall and transformingCall qualifiers
    and DataFlow::localFlow(DataFlow::exprNode(stringExpr), DataFlow::exprNode(indexReturningCall.getQualifier()))
    and DataFlow::localFlow(DataFlow::exprNode(stringExpr), DataFlow::exprNode(transformingCall.getQualifier()))
    and (
        exists(StringIndexAcceptingMethod m | m = indexUsage.getMethod() |
            indexSink = DataFlow::exprNode(indexUsage.getArgument(m.getIndexParamIndex()))
            // Method is called on String; sink is qualifier
            and transformedStringSink = DataFlow::exprNode(indexUsage.getQualifier())
        )
        or exists(ExternalStringIndexAcceptingMethod m | m = indexUsage.getMethod() |
            indexSink = DataFlow::exprNode(indexUsage.getArgument(m.getExternalStringIndexParamIndex()))
            // Method takes String as argument; sink is argument
            and transformedStringSink = DataFlow::exprNode(indexUsage.getArgument(m.getExternalStringParamIndex()))
        )
    )
    // Return value of indexReturningCall flows to indexSink
    and DataFlow::localFlow(DataFlow::exprNode(indexReturningCall), indexSink)
    // Return value of transformingCall flows to transformedStringSink
    and DataFlow::localFlow(DataFlow::exprNode(transformingCall), transformedStringSink)
select indexUsage, "Might cause IndexOutOfBoundsException or incorrect behavior because argument was obtained $@ but String was transformed $@.",
    indexReturningCall, "here", transformingCall, "here"
