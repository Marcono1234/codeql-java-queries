/**
 * Finds calls to the `String` methods `indexOf` and `lastIndexOf` which apparently
 * then only compare the returned index to check whether a substring is contained in
 * the String. For this task `String.contains(CharSequence)` should be used instead.
 */

import java

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

class MinusOne extends MinusExpr {
    MinusOne() {
        getExpr().(IntegerLiteral).getIntValue() = 1
    }
}

class Zero extends IntegerLiteral {
    Zero() {
        getIntValue() = 0
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
            and eqTest.getAnOperand() instanceof MinusOne
        )
        // Checking > -1
        or exists(GTExpr gtExpr |
            gtExpr = checkExpr
            and isContainedPolarity = true
        |
            gtExpr.getLeftOperand() = indexCall
            and gtExpr.getRightOperand() instanceof MinusOne
        )
        // Checking <= -1
        or exists(LEExpr leExpr |
            leExpr = checkExpr
            and isContainedPolarity = false
        |
            leExpr.getLeftOperand() = indexCall
            and leExpr.getRightOperand() instanceof MinusOne
        )
        // Checking >= 0
        or exists(GEExpr geExpr |
            geExpr = checkExpr
            and isContainedPolarity = true
        |
            geExpr.getLeftOperand() = indexCall
            and geExpr.getRightOperand() instanceof Zero
        )
        // Checking < 0
        or exists(LTExpr ltExpr |
            ltExpr = checkExpr
            and isContainedPolarity = false
        |
            ltExpr.getLeftOperand() = indexCall
            and ltExpr.getRightOperand() instanceof Zero
        )
    )
    and if isContainedPolarity = true then negationPrefix = ""
    else negationPrefix = "!"
select checkExpr, "Should use " + negationPrefix + "String.contains(...) instead"
