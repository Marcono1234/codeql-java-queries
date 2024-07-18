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
 *
 * @kind problem
 * @id TODO
 */

import java
import lib.AssertLib

/**
 * Expression which seems to be intended as 'expected' argument for an assertion.
 */
class ExpectedValueExpr extends Expr {
  ExpectedValueExpr() {
    // Note: Can cause false positives if the value of a constant (= 'actual') defined in the same
    // project is being checked, but on the other hand there are also cases where the constant is
    // is intended as 'expected' value
    this instanceof ConstantExpr
    or
    exists(MethodAccess call, Method m |
      call = this and
      m = call.getMethod() and
      m.isStatic() and
      forall(Expr arg | arg = call.getAnArgument() | arg instanceof ExpectedValueExpr) and
      // Only consider methods from third-party libraries or JDK, otherwise intention might be to
      // test result of method
      not m.getSourceDeclaration().fromSource()
    )
    or
    exists(ClassInstanceExpr newExpr |
      newExpr = this and
      forall(Expr arg | arg = newExpr.getAnArgument() | arg instanceof ExpectedValueExpr)
      // Do not exclude types declared in same project, assume that `newExpr` is always the 'expected' value
      // If `newExpr` is intended as 'actual' then this might be misuse of `assertEquals` for `equals`
      // implementation check (which is discouraged)
    )
    or
    exists(ArrayCreationExpr newArray | newArray = this |
      // Either creates array with constant dimensions
      forex(Expr dimExpr | dimExpr = newArray.getADimension() |
        dimExpr instanceof ExpectedValueExpr
      )
      or
      // Or with init containing constants (checked transitively)
      forex(Expr initValue | initValue = newArray.getInit().getAnInit+() |
        initValue instanceof ArrayInit or initValue instanceof ExpectedValueExpr
      )
    )
  }
}

from MethodAccess assertCall, AssertTwoArgumentsMethod assertMethod
where
  assertMethod = assertCall.getMethod() and
  assertCall.getArgument(assertMethod.getAssertionParamIndex()) instanceof ExpectedValueExpr and
  // Ignore if both arguments are constant, that is already detected by separate query
  not assertCall.getArgument(assertMethod.getFixedParamIndex()) instanceof ExpectedValueExpr
select assertCall, "Assertion arguments are switched"
