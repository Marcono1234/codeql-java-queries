/**
 * Finds calls to assertion methods which do not check array elements
 * but instead only compare the arrays by reference, but for which
 * array arguments are used. If the intention is to compare the arrays
 * for reference equality, it would be better to make this more explicit
 * by using an assertion method which only tests for reference equality,
 * such as `assertSame(...)`.
 */

import java
import lib.AssertLib

from MethodAccess assertCall, AssertEqualityMethod assertMethod
where
    assertMethod = assertCall.getMethod()
    and assertCall.getArgument(assertMethod.getAnInputParamIndex()).getType() instanceof Array
    and not assertMethod.comparesArrayElements(_)
select assertCall, "Calls assertion method which does not compare array elements"
