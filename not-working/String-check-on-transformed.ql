/**
 * Finds chained method calls on a String variable where one method call
 * transforms the String in some way (e.g. converting it to lower case)
 * and the chained call then performs some check on it (e.g. checking
 * whether String ends with some suffix).
 * Such checks are potentially incorrect when subsequent code works on the
 * original (non-transformed) String, or are error-prone when subsequent
 * code has to perform the transformation again.
 * E.g.:
 * ```
 * if (s.toUpperCase(Locale.ROOT).endsWith("suffix")) {
 *     // Incorrect, due to Unicode special casing rules `s` might be
 *     // pretty different from `s.toUpperCase`
 *     performAction(s);
 * }
 * ```
 * Instead a local variable holding the transformation result should be
 * used (or the original String variable should be reassigned):
 * ```
 * String transformed = s.toUpperCase(Locale.ROOT);
 * if (transformed.endsWith("suffix")) {
 *     performAction(transformed);
 * }
 * ```
 */
// Similar to query String-call-on-transformed-with-original-index.ql

import java
import semmle.code.java.dataflow.DataFlow

/**
 * String method which performs some kind of transformation on the String
 * qualifier.
 */
class TransformingStringMethod extends Method {
    TransformingStringMethod() {
        getDeclaringType() instanceof TypeString
        // Assume that if String is returned, it was somehow transformed
        and getReturnType() instanceof TypeString
        // Ignore `toString()` because it returns itself; this bad practice of calling
        // this method is also covered by a CodeQL query
        and not hasStringSignature("toString()")
    }
}

/**
 * String method which performs some kind of check on the String qualifier.
 */
class CheckingStringMethod extends Method {
    CheckingStringMethod() {
        getDeclaringType() instanceof TypeString
        and getReturnType().hasName(["boolean", "int"])
        // Ignore methods returning part of the content, e.g. code point
        and not hasName(["codePointAt", "codePointBefore"])
    }
}

// TODO: Might be causing too many false positives / irrelevant results
from Variable stringVar, VarAccess firstAccess, MethodAccess transformingCall, MethodAccess checkingCall, VarAccess subsequentAccess
where
    transformingCall.getMethod() instanceof TransformingStringMethod
    and checkingCall.getMethod() instanceof CheckingStringMethod
    // Match chain: transform().check()
    and checkingCall.getQualifier().(MethodAccess) = transformingCall
    and firstAccess = stringVar.getAnAccess()
    and transformingCall.getQualifier() = firstAccess
    and subsequentAccess = stringVar.getAnAccess()
    // Subsequent access happens after transformation
    and transformingCall.getControlFlowNode().getANormalSuccessor+() = subsequentAccess.getControlFlowNode()
    // And there is flow to subsequent access (i.e. no reassignment in between)
    and DataFlow::localFlow(DataFlow::exprNode(firstAccess), DataFlow::exprNode(subsequentAccess))
select checkingCall, "Performs check on transformed String before accessing original String $@", subsequentAccess, "here"
