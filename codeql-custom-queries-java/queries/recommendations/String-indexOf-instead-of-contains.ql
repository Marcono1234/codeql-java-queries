/**
 * Finds calls to the `String` methods `indexOf` and `lastIndexOf` which apparently
 * then only compare the returned index to check whether a substring is contained in
 * the String. For this task `String.contains(CharSequence)` should be used instead.
 */

import java

import lib.Expressions

class IndexMethod extends Method {
    IndexMethod() {
        getDeclaringType() instanceof TypeString
        and getStringSignature() in [
            // Don't consider overloads for finding code point index, converting code
            // point to String to be able to use contains(...) might have some overhead
            "indexOf(String)",
            "lastIndexOf(String)"
        ]
    }
}

from BinaryExpr checkExpr, MethodAccess indexCall, boolean isContainedPolarity, string negationPrefix
where
    indexCall.getMethod() instanceof IndexMethod
    and (
        // Checking != -1 or == -1
        exists(EqualityTest eqTest |
            eqTest = checkExpr
            and isContainedPolarity = eqTest.polarity().booleanNot()
        |
            eqTest.getAnOperand() = indexCall
            and eqTest.getAnOperand().(CompileTimeConstantExpr).getIntValue() = -1
        )
        // Performs some check similar to >= 0
        or comparesWithConstant(checkExpr, indexCall, 0, isContainedPolarity)
    )
    and if isContainedPolarity = true then negationPrefix = ""
    else negationPrefix = "!"
select checkExpr, "Should use " + negationPrefix + "String.contains(...) instead"
