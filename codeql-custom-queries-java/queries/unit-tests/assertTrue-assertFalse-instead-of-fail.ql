/**
 * Finds assertion method calls in the form `assertTrue(false)` or `assertFalse(true)`.
 * Many assertion libraries provide a method for explicitly failing a test (e.g. `fail(...)`).
 * Such a method should be preferred because the desired outcome for it is clearer.
 */

import java
import lib.AssertLib

from MethodAccess assertCall, AssertBooleanMethod assertMethod, boolean booleanArg
where
    assertMethod = assertCall.getMethod()
    and booleanArg = assertCall.getArgument(assertMethod.getAssertionParamIndex()).(BooleanLiteral).getBooleanValue()
    // And boolean constant is not the expected one
    and booleanArg = assertMethod.polarity().booleanNot()
select assertCall, "Should use assertion method for explicitly failing a test, e.g. `fail(...)`"
