/**
 * Finds calls to an `assertNotEquals(...)` assertion method with `null` as
 * argument. The intention of the test author might be to verify that `equals(...)`
 * of a class is correctly implemented so that `equals(null)` return `false`.
 * However, most assertion libraries are designed with the intention to compare
 * different values, and therefore often a call to `assertNotEquals(...)` with
 * `null` returns fast without even calling the `equals` method.  
 * It would therefore be better to perform the check explicitly, e.g.:
 * `assertFalse(obj.equals(null))`
 */

import java
import lib.AssertLib

from MethodAccess assertCall, AssertNotEqualsMethod assertMethod
where
    assertMethod = assertCall.getMethod()
    and assertCall.getArgument(assertMethod.getAnInputParamIndex()) instanceof NullLiteral
select assertCall, "Should use explicit check that `obj.equals(null)` is false"
