/**
 * Finds boolean operations using operators such as `&&` or `||` whose result is
 * then used for a boolean assertion call. Such code can cause ambiguous test
 * failures which require running the test in debug mode again to find out why
 * exactly the test failed.
 * 
 * For example:
 * ```java
 * boolean result1 = ...
 * boolean result2 = ...
 * 
 * // Bad: When this fails it is unclear whether result1 or both result1 and result2 were `false`
 * assertTrue(result1 && result2);
 * ```
 * 
 * Instead for each boolean result a separate assertion call should be made:
 * ```java
 * boolean result1 = ...
 * assertTrue(result1);
 * 
 * boolean result2 = ...
 * assertTrue(result2);
 * ```
 */

import java
import semmle.code.java.dataflow.DataFlow
import lib.Operations
import lib.AssertLib

from BinaryExpr source, MethodAccess assertionCall, AssertBooleanMethod assertMethod
where
    assertMethod = assertionCall.getMethod()
    and DataFlow::localExprFlow(source, assertionCall.getArgument(assertMethod.getAnInputParamIndex()))
    and (
        assertMethod.expectedBooleanValue() = true
        and source instanceof AndOperation
        or
        assertMethod.expectedBooleanValue() = false
        and source instanceof OrOperation
        or
        // For XOR it is unclear whether both operands were true, or both were false
        source instanceof XorBitwiseExpr
    )
select source, "Boolean operation can cause ambigious failure for $@ assertion call", assertionCall, "this"
