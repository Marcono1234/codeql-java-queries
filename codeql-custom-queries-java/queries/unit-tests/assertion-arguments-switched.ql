/**
 * Finds assertion method calls which appear to have switched the *expected*
 * and *actual* arguments. This will lead to confusing error messages in case
 * the test fails. E.g.:
 * ```java
 * // JUnit 5
 * String actual = ...;
 * // Arguments are switched, signature is: assertEquals(expected, actual)
 * assertEquals(actual, "expected");
 * ```
 * SonarSource rule: [RSPEC-3415](https://rules.sonarsource.com/java/RSPEC-3415)
 */

 import java
 import lib.AssertLib

 from MethodAccess assertCall, AssertTwoArgumentsMethod assertMethod
where
    assertMethod = assertCall.getMethod()
    and assertCall.getArgument(assertMethod.getAssertionParamIndex()) instanceof CompileTimeConstantOrLiteral
    // Ignore if both arguments are constant, that is already detected by separate query
    and not assertCall.getArgument(assertMethod.getFixedParamIndex()) instanceof CompileTimeConstantOrLiteral
select assertCall, "Assertion arguments are switched"
