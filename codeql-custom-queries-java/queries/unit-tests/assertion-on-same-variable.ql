/**
 * Finds assertion methods for comparing two arguments, which are called with
 * same variable twice. This likely indicates a bug in the test. E.g.:
 * ```java
 * // Called with the same variable twice
 * assertEquals(actual, actual);
 * ```
 * If the intention is to verify that the `equals(...)` implementation of a
 * class is implemented correctly to detect `this.equals(this)`, then it is
 * better to explicitly write this: `assertTrue(obj.equals(obj))`  
 * Otherwise future readers might be confused, or the assertion might actually
 * be a no-op in case the assertion library returns fast when the same arguments
 * are provided.
 */

import java
import lib.AssertLib
import lib.VarAccess

from MethodAccess assertCall, AssertTwoArgumentsMethod assertMethod
where
    assertMethod = assertCall.getMethod()
    and accessSameVarOfSameOwner(
        assertCall.getArgument(assertMethod.getFixedParamIndex()),
        assertCall.getArgument(assertMethod.getAssertionParamIndex())
    )
select assertCall, "Assertion compares variable with itself"
