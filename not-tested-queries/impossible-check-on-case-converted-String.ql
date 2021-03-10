/**
 * Finds calls which perform a check on the result of a String case conversion
 * with an argument which will never match because it uses the opposite casing.
 * E.g.:
 * ```
 * // Impossible because lower cased result cannot contain upper case 'T'
 * if (s.toLowerCase(Locale.ROOT).equals("Test")) {
 *    ...
 * }
 * ```
 */

import java
import semmle.code.java.dataflow.DataFlow

class StringCasingMethod extends Method {
    string impossibleCharacterClass;
    
    StringCasingMethod() {
        getDeclaringType() instanceof TypeString
        and (
            hasName("toLowerCase") and impossibleCharacterClass = "\\p{javaUpperCase}"
            or hasName("toUpperCase") and impossibleCharacterClass = "\\p{javaLowerCase}"
        )
    }
    
    /**
     * Gets the `Pattern` regex character class which the result of this method
     * will never match.
     */
    string getImpossibleCharacterClass() {
        result = impossibleCharacterClass
    }
}

abstract class StringContentCheckingCall extends MethodAccess {
    StringContentCheckingCall() {
        getMethod().getDeclaringType() instanceof TypeString
    }
    
    /**
     * `true` if any impossible char in `otherExpr` makes the complete check
     * impossible;
     * `false` if only when all chars of `otherExpr` are impossible, check becomes
     * impossible.
     */
    abstract boolean isImpossibleIfAnyMismatch(Expr convertedExpr, Expr otherExpr);
}

class CompleteContentCheckingCall extends StringContentCheckingCall {
    CompleteContentCheckingCall() {
        exists(Method m | m = getMethod() |
            m instanceof EqualsMethod
            or m.hasStringSignature("contentEquals(CharSequence)")
        )
    }
    
    override
    boolean isImpossibleIfAnyMismatch(Expr convertedExpr, Expr otherExpr) {
        // Methods check whether content exactly matches, so any casing mismatch
        // makes check impossible
        result = true
        and (
            convertedExpr = getQualifier() and otherExpr = getArgument(0)
            or convertedExpr = getArgument(0) and otherExpr = getQualifier()
        )
    }
}

class SubstringCheckingCall extends StringContentCheckingCall {
    Expr substringExpr;
    
    SubstringCheckingCall() {
        exists(Method m | m = getMethod() |
            m.hasName([
                "contains",
                "endsWith", "startsWith",
                "indexOf", "lastIndexOf",
                "replace" // Replaces substring
            ]) and substringExpr = getArgument(0)
            or (
                m.hasName("regionMatches")
                and m.getNumberOfParameters() = 5
                // Case sensitive
                and getArgument(0).(BooleanLiteral).getBooleanValue() = false
                and substringExpr = getArgument(2)
            )
            or (
                m.hasName("regionMatches")
                and m.getNumberOfParameters() = 4
                and substringExpr = getArgument(1)
            )
        )
    }
    
    override
    boolean isImpossibleIfAnyMismatch(Expr convertedExpr, Expr otherExpr) {
        // If converted is qualifier, then any mismatch makes check impossible
        // E.g. "Abc".toLowerCase().indexOf("Bc")
        result = true and convertedExpr = getQualifier() and otherExpr = getArgument(0)
        // If converted is argument, then all chars of `otherExpr` must not
        // match, e.g. `"Test".contains(s.toUpperCase())` might succeed, but
        // `"test".contains(s.toUpperCase())` won't
        or result = false and convertedExpr = getArgument(0) and otherExpr = getQualifier()
    }
}

private CompileTimeConstantExpr getAStringPiece(Expr e) {
    result.getType() instanceof TypeString
    and (
        result = e
        // Or result is part of String concatenation
        or result = e.(AddExpr).getAnOperand+()
    )
}

from MethodAccess casingCall, StringCasingMethod casingMethod, StringContentCheckingCall checkingCall, Expr otherStrExpr, CompileTimeConstantExpr impossibleStrExpr, string impossibleStr
where
    casingCall.getMethod() = casingMethod
    and exists(Expr casingResultSink, boolean anyMismatch |
        anyMismatch = checkingCall.isImpossibleIfAnyMismatch(casingResultSink, otherStrExpr)
        and DataFlow::localFlow(DataFlow::exprNode(casingCall), DataFlow::exprNode(casingResultSink))
    |
        if anyMismatch = true then (
            // Suffices if any String piece is impossible
            impossibleStrExpr = getAStringPiece(otherStrExpr)
            // Any char in String piece is impossible
            and exists(impossibleStr.regexpFind(casingMethod.getImpossibleCharacterClass(), _, _))
        )
        else (
            // Complete other String must be impossible
            impossibleStrExpr = otherStrExpr
            and impossibleStr.regexpMatch(casingMethod.getImpossibleCharacterClass() + "+")
        )
    )
    and impossibleStr = impossibleStrExpr.getStringValue()
select checkingCall, "Will never succeed because result of $@ case conversion call will never be equal to $@",
    casingCall, "this", impossibleStrExpr, impossibleStr
