/**
 * Finds calls to assertion methods, which are called with only constant value
 * arguments. The assertion will therefore either always succeed or fail,
 * regardless of the behavior of the tested code.
 * This might indicate a bug in the test, or might be misuse of the assertion
 * method, e.g. when it is desired to manually fail a test `fail(...)` should
 * be used instead of `assertTrue(false)` or similar.
 * 
 * SonarSource rule: [RSPEC-2701](https://rules.sonarsource.com/java/RSPEC-2701)
 */

import java
import lib.AssertLib

from MethodAccess assertCall, AssertMethod assertMethod
where
    assertMethod = assertCall.getMethod()
    and forex(int inputParamIndex | inputParamIndex = assertMethod.getAnInputParamIndex() |
        assertCall.getArgument(inputParamIndex) instanceof ConstantExpr
    )
select assertCall, "Assertion will always have the same outcome"
