import java

/**
 * Base class for all assertion methods.
 */
abstract class AssertMethod extends Method {
  /**
   * Gets the index of a parameter which is considered as part of the
   * assertion. This will not include message parameters, if any.
   */
  abstract int getAnInputParamIndex();
}

/**
 * Assertion method which unconditionally causes a test failure.
 */
abstract class FailMethod extends AssertMethod {
  override
  int getAnInputParamIndex() {
    none()
  }
}

/**
 * Base class for all assertion methods performing an assertion on a single argument.
 */
abstract class AssertOneArgumentMethod extends AssertMethod {
  /**
   * Gets the index of the parameter on which the assertion is performed.
   */
  abstract int getAssertionParamIndex();

  override
  int getAnInputParamIndex() {
    result = getAssertionParamIndex()
  }
}

/**
 * Base class for all assertion methods performing an assertion on two arguments.
 */
abstract class AssertTwoArgumentsMethod extends AssertMethod {
  /**
   * Gets the index of a parameter which is considered as part of the
   * assertion. That includes the fixed ('expected' or 'unexpected') parameter
   * as well as the 'actual' parameter on which the assertion is performed.
   */
  override
  int getAnInputParamIndex() {
    result = [getFixedParamIndex(), getAssertionParamIndex()]
  }

  /**
   * Gets the index of the parameter which is provided as fixed value by the
   * test case, i.e. the 'expected' or 'unexpected' value.
   */
  abstract int getFixedParamIndex();

  /**
   * Gets the index of the parameter which is compared with the fixed value,
   * i.e. the 'actual' value on which the assertion is performed.
   */
  abstract int getAssertionParamIndex();
}

/**
 * Base class for methods performing an assertion on a boolean value.
 */
abstract class AssertBooleanMethod extends AssertOneArgumentMethod {
  /**
   * `true` if this method expects that the checked argument is `true`,
   * `false` if this method expects that the checked argument is `false`.
   */
  abstract boolean polarity();
}

abstract class AssertTrueMethod extends AssertBooleanMethod {
  override
  boolean polarity() {
    result = true
  }
}

abstract class AssertFalseMethod extends AssertBooleanMethod {
  override
  boolean polarity() {
    result = false
  }
}

abstract class AssertEqualityMethod extends AssertTwoArgumentsMethod {
  /**
   * `true` if this method expects that the checked arguments are equal,
   * `false` if this method expects that the checked arguments are not equal.
   */
  abstract boolean polarity();

  /**
   * Holds if this assertion method compares array elements (instead of only
   * comparing the arrays by reference). If `deepEquals` is `true` the array
   * elements are compared deeply (i.e. nested array elements are compared
   * as well), if `false` the elements are not compared deeply.
   */
  abstract predicate comparesArrayElements(boolean deepEquals);
}

abstract class AssertEqualsMethod extends AssertEqualityMethod {
  override
  boolean polarity() {
    result = true
  }
}

abstract class AssertNotEqualsMethod extends AssertEqualityMethod {
  override
  boolean polarity() {
    result = false
  }
}

abstract class AssertIdentityMethod extends AssertTwoArgumentsMethod {
  /**
   * `true` if this method expects that the checked arguments are the same,
   * `false` if this method expects that the checked arguments are not the same.
   */
  abstract boolean polarity();
}

abstract class AssertSameMethod extends AssertIdentityMethod {
  override
  boolean polarity() {
    result = true
  }
}

abstract class AssertNotSameMethod extends AssertIdentityMethod {
  override
  boolean polarity() {
    result = false
  }
}

abstract class AssertNullnessMethod extends AssertOneArgumentMethod {
  /**
   * `true` if this method expects that the checked argument is `null`,
   * `false` if this method expects that the checked argument is non-`null`.
   */
  abstract boolean polarity();
}

abstract class AssertNullMethod extends AssertNullnessMethod {
  override
  boolean polarity() {
    result = true
  }
}

abstract class AssertNotNullMethod extends AssertNullnessMethod {
  override
  boolean polarity() {
    result = false
  }
}

abstract class AssertThrowsMethod extends AssertMethod {
  /**
   * Gets the index of the parameter representing the expected exception class.
   * Has no result if this assertion method does not have a parameter for the
   * expected exception class and instead expects any exception.
   */
  abstract int getExpectedClassParamIndex();

  /**
   * Gets the index of the parameter representing the executable object causing
   * the expected exception.
   */
  abstract int getExecutableParamIndex();

  override
  int getAnInputParamIndex() {
    result = [getExpectedClassParamIndex(), getExecutableParamIndex()]
  }

  /**
   * Holds if this assertion method returns the caught exception.
   */
  abstract predicate returnsException();

  /**
   * Holds if this assertion method allows exception subtypes.
   */
  predicate allowsExceptionSubtypes() {
    any()
  }
}

abstract class JUnit4AssertionMethod extends Method {
}

class TypeJUnit4Assert extends Class {
  TypeJUnit4Assert() {
    hasQualifiedName("org.junit", "Assert")
    // TestNG has an AssertJUnit class which might originate from JUnit 4, or even JUnit 3
    // for simplicity pretend it is a JUnit 4 Assert class
    or hasQualifiedName("org.testng", "AssertJUnit")
  }
}

class JUnit4AssertTrue extends AssertTrueMethod, JUnit4AssertionMethod {
  JUnit4AssertTrue() {
    getDeclaringType() instanceof TypeJUnit4Assert
    and hasName("assertTrue")
  }

  override
  int getAssertionParamIndex() {
    result = getNumberOfParameters() - 1
  }
}

class JUnit4AssertFalse extends AssertFalseMethod, JUnit4AssertionMethod {
  JUnit4AssertFalse() {
    getDeclaringType() instanceof TypeJUnit4Assert
    and hasName("assertFalse")
  }

  override
  int getAssertionParamIndex() {
    result = getNumberOfParameters() - 1
  }
}

class JUnit4AssertNull extends AssertNullMethod, JUnit4AssertionMethod {
  JUnit4AssertNull() {
    getDeclaringType() instanceof TypeJUnit4Assert
    and hasName("assertNull")
  }

  override
  int getAssertionParamIndex() {
    result = getNumberOfParameters() - 1
  }
}

class JUnit4AssertNotNull extends AssertNotNullMethod, JUnit4AssertionMethod {
  JUnit4AssertNotNull() {
    getDeclaringType() instanceof TypeJUnit4Assert
    and hasName("assertNotNull")
  }

  override
  int getAssertionParamIndex() {
    result = getNumberOfParameters() - 1
  }
}

class JUnit4AssertEquals extends AssertEqualsMethod, JUnit4AssertionMethod {
  int messageOffset;

  JUnit4AssertEquals() {
    getDeclaringType() instanceof TypeJUnit4Assert
    and hasName("assertEquals")
    and if getParameterType(0) instanceof TypeString then messageOffset = 1
    else messageOffset = 0
  }

  override
  int getFixedParamIndex() {
    result = messageOffset + 0
  }

  override
  int getAssertionParamIndex() {
    result = messageOffset + 1
  }

  override
  predicate comparesArrayElements(boolean deepEquals) {
    // Has deprecated overloads for comparing arrays
    getParameterType(getFixedParamIndex()) instanceof Array and deepEquals = true
  }
}

class JUnit4AssertArrayEquals extends AssertEqualsMethod, JUnit4AssertionMethod {
  int messageOffset;

  JUnit4AssertArrayEquals() {
    getDeclaringType() instanceof TypeJUnit4Assert
    and hasName("assertArrayEquals")
    and if getParameterType(0) instanceof TypeString then messageOffset = 1
    else messageOffset = 0
  }

  override
  int getFixedParamIndex() {
    result = messageOffset + 0
  }

  override
  int getAssertionParamIndex() {
    result = messageOffset + 1
  }

  override
  predicate comparesArrayElements(boolean deepEquals) { deepEquals = true }
}

class JUnit4AssertNotEquals extends AssertNotEqualsMethod, JUnit4AssertionMethod {
  int messageOffset;

  JUnit4AssertNotEquals() {
    getDeclaringType() instanceof TypeJUnit4Assert
    and hasName("assertNotEquals")
    and if getParameterType(0) instanceof TypeString then messageOffset = 1
    else messageOffset = 0
  }

  override
  int getFixedParamIndex() {
    result = messageOffset + 0
  }

  override
  int getAssertionParamIndex() {
    result = messageOffset + 1
  }

  override
  predicate comparesArrayElements(boolean deepEquals) { none() }
}

class JUnit4AssertSame extends AssertSameMethod, JUnit4AssertionMethod {
  int messageOffset;

  JUnit4AssertSame() {
    getDeclaringType() instanceof TypeJUnit4Assert
    and hasName("assertSame")
    and if getParameterType(0) instanceof TypeString then messageOffset = 1
    else messageOffset = 0
  }

  override
  int getFixedParamIndex() {
    result = messageOffset + 0
  }

  override
  int getAssertionParamIndex() {
    result = messageOffset + 1
  }
}

class JUnit4AssertNotSame extends AssertNotSameMethod, JUnit4AssertionMethod {
  int messageOffset;

  JUnit4AssertNotSame() {
    getDeclaringType() instanceof TypeJUnit4Assert
    and hasName("assertNotSame")
    and if getParameterType(0) instanceof TypeString then messageOffset = 1
    else messageOffset = 0
  }

  override
  int getFixedParamIndex() {
    result = messageOffset + 0
  }

  override
  int getAssertionParamIndex() {
    result = messageOffset + 1
  }
}

class JUnit4AssertThrows extends AssertThrowsMethod, JUnit4AssertionMethod {
  int messageOffset;

  JUnit4AssertThrows() {
    getDeclaringType() instanceof TypeJUnit4Assert
    and hasName("assertThrows")
    and if getParameterType(0) instanceof TypeString then messageOffset = 1
    else messageOffset = 0
  }

  override
  int getExpectedClassParamIndex() {
    result = messageOffset + 0
  }

  override
  int getExecutableParamIndex() {
    result = messageOffset + 1
  }

  override
  predicate returnsException() {
    any()
  }
}

class TypeJUnit4ErrorCollector extends Class {
  TypeJUnit4ErrorCollector() {
    hasQualifiedName("org.junit.rules", "ErrorCollector")
  }
}

class JUnit4CheckThrows extends AssertThrowsMethod, JUnit4AssertionMethod {
  JUnit4CheckThrows() {
    getDeclaringType().getASourceSupertype*() instanceof TypeJUnit4ErrorCollector
    and hasName("checkThrows")
  }

  override
  int getExpectedClassParamIndex() {
    result = 0
  }

  override
  int getExecutableParamIndex() {
    result = 1
  }

  override
  predicate returnsException() {
    none()
  }
}

class JUnit4Fail extends FailMethod, JUnit4AssertionMethod {
  JUnit4Fail() {
    getDeclaringType() instanceof TypeJUnit4Assert
    and hasName("fail")
  }
}

// Consider JUnit 4 Assume as well; it is not exactly the same
// as Assert, but similar enough to be relevant for most queries
class TypeJUnit4Assume extends Class {
  TypeJUnit4Assume() {
    hasQualifiedName("org.junit", "Assume")
  }
}

class JUnit4AssumeTrue extends AssertTrueMethod, JUnit4AssertionMethod {
  JUnit4AssumeTrue() {
    getDeclaringType() instanceof TypeJUnit4Assume
    and hasName("assumeTrue")
  }

  override
  int getAssertionParamIndex() {
    result = getNumberOfParameters() - 1
  }
}

class JUnit4AssumeFalse extends AssertFalseMethod, JUnit4AssertionMethod {
  JUnit4AssumeFalse() {
    getDeclaringType() instanceof TypeJUnit4Assume
    and hasName("assumeFalse")
  }

  override
  int getAssertionParamIndex() {
    result = getNumberOfParameters() - 1
  }
}

class JUnit4AssumeNoException extends AssertMethod, JUnit4AssertionMethod {
  JUnit4AssumeNoException() {
    getDeclaringType() instanceof TypeJUnit4Assume
    and hasName("assumeNoException")
  }

  override
  int getAnInputParamIndex() {
    result = getNumberOfParameters() - 1
  }
}

class JUnit4AssumeNotNull extends AssertNotNullMethod, JUnit4AssertionMethod {
  JUnit4AssumeNotNull() {
    getDeclaringType() instanceof TypeJUnit4Assume
    and hasName("assumeNotNull")
  }

  override
  int getAssertionParamIndex() {
    // TODO: Actually elements of (varargs) array are checked as well, but this can
    // currently not be modeled here
    result = 0
  }
}

class JUnit4AssumeThat extends AssertMethod, JUnit4AssertionMethod {
  int messageOffset;

  JUnit4AssumeThat() {
    getDeclaringType() instanceof TypeJUnit4Assume
    and hasName("assumeThat")
    and if getParameterType(0) instanceof TypeString then messageOffset = 1
    else messageOffset = 0
  }

  override
  int getAnInputParamIndex() {
    result = messageOffset + 0
  }
}

abstract class JUnit5AssertionMethod extends Method {
}

class TypeJUnit5Assertions extends Class {
  TypeJUnit5Assertions() {
    hasQualifiedName("org.junit.jupiter.api", "Assertions")
  }
}

class JUnit5AssertTrue extends AssertTrueMethod, JUnit5AssertionMethod {
  JUnit5AssertTrue() {
    getDeclaringType() instanceof TypeJUnit5Assertions
    and hasName("assertTrue")
    // Ignore assertTrue with BooleanSupplier
    and getParameterType(0) instanceof BooleanType
  }

  override
  int getAssertionParamIndex() {
    result = 0
  }
}

class JUnit5AssertFalse extends AssertFalseMethod, JUnit5AssertionMethod {
  JUnit5AssertFalse() {
    getDeclaringType() instanceof TypeJUnit5Assertions
    and hasName("assertFalse")
    // Ignore assertFalse with BooleanSupplier
     and getParameterType(0) instanceof BooleanType
  }

  override
  int getAssertionParamIndex() {
    result = 0
  }
}

class JUnit5AssertNull extends AssertNullMethod, JUnit5AssertionMethod {
  JUnit5AssertNull() {
    getDeclaringType() instanceof TypeJUnit5Assertions
    and hasName("assertNull")
  }

  override
  int getAssertionParamIndex() {
    result = 0
  }
}

class JUnit5AssertNotNull extends AssertNotNullMethod, JUnit5AssertionMethod {
  JUnit5AssertNotNull() {
    getDeclaringType() instanceof TypeJUnit5Assertions
    and hasName("assertNotNull")
  }

  override
  int getAssertionParamIndex() {
    result = 0
  }
}

class JUnit5AssertEquals extends AssertEqualsMethod, JUnit5AssertionMethod {
  JUnit5AssertEquals() {
    getDeclaringType() instanceof TypeJUnit5Assertions
    and hasName("assertEquals")
  }

  override
  int getFixedParamIndex() {
    result = 0
  }

  override
  int getAssertionParamIndex() {
    result = 1
  }

  override
  predicate comparesArrayElements(boolean deepEquals) { none() }
}

class JUnit5AssertArrayEquals extends AssertEqualsMethod, JUnit5AssertionMethod {
  JUnit5AssertArrayEquals() {
    getDeclaringType() instanceof TypeJUnit5Assertions
    and hasName("assertArrayEquals")
  }

  override
  int getFixedParamIndex() {
    result = 0
  }

  override
  int getAssertionParamIndex() {
    result = 1
  }

  override
  predicate comparesArrayElements(boolean deepEquals) { deepEquals = true }
}

class JUnit5AssertIterableEquals extends AssertEqualsMethod, JUnit5AssertionMethod {
  JUnit5AssertIterableEquals() {
    getDeclaringType() instanceof TypeJUnit5Assertions
    and hasName("assertIterableEquals")
  }

  override
  int getFixedParamIndex() {
    result = 0
  }

  override
  int getAssertionParamIndex() {
    result = 1
  }

  override
  predicate comparesArrayElements(boolean deepEquals) {
    // Does not matter; arrays cannot be provided as argument
    none()
  }
}

// Not a subclass of AssertEqualsMethod because lines are not matched exactly
class JUnit5AssertLinesMatch extends AssertTwoArgumentsMethod, JUnit5AssertionMethod {
  JUnit5AssertLinesMatch() {
    getDeclaringType() instanceof TypeJUnit5Assertions
    and hasName("assertLinesMatch")
  }

  override
  int getFixedParamIndex() {
    result = 0
  }

  override
  int getAssertionParamIndex() {
    result = 1
  }
}

class JUnit5AssertNotEquals extends AssertNotEqualsMethod, JUnit5AssertionMethod {
  JUnit5AssertNotEquals() {
    getDeclaringType() instanceof TypeJUnit5Assertions
    and hasName("assertNotEquals")
  }

  override
  int getFixedParamIndex() {
    result = 0
  }

  override
  int getAssertionParamIndex() {
    result = 1
  }

  override
  predicate comparesArrayElements(boolean deepEquals) { none() }
}

class JUnit5AssertSame extends AssertSameMethod, JUnit5AssertionMethod {
  JUnit5AssertSame() {
    getDeclaringType() instanceof TypeJUnit5Assertions
    and hasName("assertSame")
  }

  override
  int getFixedParamIndex() {
    result = 0
  }

  override
  int getAssertionParamIndex() {
    result = 1
  }
}

class JUnit5AssertNotSame extends AssertNotSameMethod, JUnit5AssertionMethod {
  JUnit5AssertNotSame() {
    getDeclaringType() instanceof TypeJUnit5Assertions
    and hasName("assertNotSame")
  }

  override
  int getFixedParamIndex() {
    result = 0
  }

  override
  int getAssertionParamIndex() {
    result = 1
  }
}

class JUnit5AssertThrows extends AssertThrowsMethod, JUnit5AssertionMethod {
  JUnit5AssertThrows() {
    getDeclaringType() instanceof TypeJUnit5Assertions
    and hasName("assertThrows")
  }

  override
  int getExpectedClassParamIndex() {
    result = 0
  }

  override
  int getExecutableParamIndex() {
    result = 1
  }

  override
  predicate returnsException() {
    any()
  }
}

class JUnit5AssertThrowsExactly extends AssertThrowsMethod, JUnit5AssertionMethod {
  JUnit5AssertThrowsExactly() {
    getDeclaringType() instanceof TypeJUnit5Assertions
    and hasName("assertThrowsExactly")
  }

  override
  int getExpectedClassParamIndex() {
    result = 0
  }

  override
  int getExecutableParamIndex() {
    result = 1
  }

  override
  predicate returnsException() {
    any()
  }

  override
  predicate allowsExceptionSubtypes() {
    none()
  }
}

class JUnit5Fail extends FailMethod, JUnit5AssertionMethod {
  JUnit5Fail() {
    getDeclaringType() instanceof TypeJUnit5Assertions
    and hasName("fail")
  }
}

// Consider JUnit 5 Assumptions as well; it is not exactly the same
// as Assertions, but similar enough to be relevant for most queries
class TypeJUnit5Assumptions extends Class {
  TypeJUnit5Assumptions() {
    hasQualifiedName("org.junit.jupiter.api", "Assumptions")
  }
}

class JUnit5AssumeTrue extends AssertTrueMethod, JUnit5AssertionMethod {
  JUnit5AssumeTrue() {
    getDeclaringType() instanceof TypeJUnit5Assumptions
    and hasName("assumeTrue")
    // Ignore assumeTrue with BooleanSupplier
    and getParameterType(0) instanceof BooleanType
  }

  override
  int getAssertionParamIndex() {
    result = 0
  }
}

class JUnit5AssumingThat extends AssertTrueMethod, JUnit5AssertionMethod {
  JUnit5AssumingThat() {
    getDeclaringType() instanceof TypeJUnit5Assumptions
    and hasName("assumingThat")
    // Ignore assumingThat with BooleanSupplier
    and getParameterType(0) instanceof BooleanType
  }

  override
  int getAssertionParamIndex() {
    result = 0
  }
}

class JUnit5AssumeFalse extends AssertFalseMethod, JUnit5AssertionMethod {
  JUnit5AssumeFalse() {
    getDeclaringType() instanceof TypeJUnit5Assumptions
    and hasName("assumeFalse")
    // Ignore assumeFalse with BooleanSupplier
     and getParameterType(0) instanceof BooleanType
  }

  override
  int getAssertionParamIndex() {
    result = 0
  }
}

class TypeTestNgAssert extends Class {
  TypeTestNgAssert() {
    hasQualifiedName("org.testng", "Assert")
    // Assertion class has instance methods which appear to be the same as Assert ones
    or hasQualifiedName("org.testng.asserts", "Assertion")
  }
}

class TestNgAssertTrue extends AssertTrueMethod {
  TestNgAssertTrue() {
    getDeclaringType() instanceof TypeTestNgAssert
    and hasName("assertTrue")
  }

  override
  int getAssertionParamIndex() {
    result = 0
  }
}

class TestNgAssertFalse extends AssertFalseMethod {
  TestNgAssertFalse() {
    getDeclaringType() instanceof TypeTestNgAssert
    and hasName("assertFalse")
  }

  override
  int getAssertionParamIndex() {
    result = 0
  }
}

class TestNgAssertNull extends AssertNullMethod {
  TestNgAssertNull() {
    getDeclaringType() instanceof TypeTestNgAssert
    and hasName("assertNull")
  }

  override
  int getAssertionParamIndex() {
    result = 0
  }
}

class TestNgAssertNotNull extends AssertNotNullMethod {
  TestNgAssertNotNull() {
    getDeclaringType() instanceof TypeTestNgAssert
    and hasName("assertNotNull")
  }

  override
  int getAssertionParamIndex() {
    result = 0
  }
}

class TestNgAssertEquals extends AssertEqualsMethod {
  TestNgAssertEquals() {
    getDeclaringType() instanceof TypeTestNgAssert
    and hasName("assertEquals")
  }

  override
  int getFixedParamIndex() {
    result = 1
  }

  override
  int getAssertionParamIndex() {
    result = 0
  }

  override
  predicate comparesArrayElements(boolean deepEquals) { deepEquals = true }
}

class TestNgAssertEqualsDeep extends AssertEqualsMethod {
  TestNgAssertEqualsDeep() {
    getDeclaringType() instanceof TypeTestNgAssert
    and hasName("assertEqualsDeep")
  }

  override
  int getFixedParamIndex() {
    result = 1
  }

  override
  int getAssertionParamIndex() {
    result = 0
  }

  override
  predicate comparesArrayElements(boolean deepEquals) {
    // Does not matter; arrays cannot be provided as argument
    none()
  }
}

class TestNgAssertEqualsNoOrder extends AssertEqualsMethod {
  TestNgAssertEqualsNoOrder() {
    getDeclaringType() instanceof TypeTestNgAssert
    and hasName("assertEqualsNoOrder")
  }

  override
  int getFixedParamIndex() {
    result = 1
  }

  override
  int getAssertionParamIndex() {
    result = 0
  }

  override
  predicate comparesArrayElements(boolean deepEquals) {
    // Does not compare deeply, see https://github.com/cbeust/testng/issues/2500
    deepEquals = false
  }
}

class TestNgAssertNotEquals extends AssertNotEqualsMethod {
  TestNgAssertNotEquals() {
    getDeclaringType() instanceof TypeTestNgAssert
    and hasName("assertNotEquals")
  }

  override
  int getFixedParamIndex() {
    result = 1
  }

  override
  int getAssertionParamIndex() {
    result = 0
  }

  override
  predicate comparesArrayElements(boolean deepEquals) { deepEquals = true }
}

class TestNgAssertNotEqualsDeep extends AssertNotEqualsMethod {
  TestNgAssertNotEqualsDeep() {
    getDeclaringType() instanceof TypeTestNgAssert
    and hasName("assertNotEqualsDeep")
  }

  override
  int getFixedParamIndex() {
    result = 1
  }

  override
  int getAssertionParamIndex() {
    result = 0
  }

  override
  predicate comparesArrayElements(boolean deepEquals) {
    // Does not matter; arrays cannot be provided as argument
    none()
  }
}

class TestNgAssertSame extends AssertSameMethod {
  TestNgAssertSame() {
    getDeclaringType() instanceof TypeTestNgAssert
    and hasName("assertSame")
  }

  override
  int getFixedParamIndex() {
    result = 1
  }

  override
  int getAssertionParamIndex() {
    result = 0
  }
}

class TestNgAssertNotSame extends AssertNotSameMethod {
  TestNgAssertNotSame() {
    getDeclaringType() instanceof TypeTestNgAssert
    and hasName("assertNotSame")
  }

  override
  int getFixedParamIndex() {
    result = 1
  }

  override
  int getAssertionParamIndex() {
    result = 0
  }
}

class TestNgAssertThrows extends AssertThrowsMethod {
  boolean hasExceptionParam;

  TestNgAssertThrows() {
    getDeclaringType() instanceof TypeTestNgAssert
    and hasName("assertThrows")
    and if getNumberOfParameters() = 2 then hasExceptionParam = true
    else hasExceptionParam = false
  }

  override
  int getExpectedClassParamIndex() {
    if hasExceptionParam = false then none()
    else result = 0
  }

  override
  int getExecutableParamIndex() {
    if hasExceptionParam = false then result = 0
    else result = 1
  }

  override
  predicate returnsException() {
    none()
  }
}

class TestNgExpectThrows extends AssertThrowsMethod {
  TestNgExpectThrows() {
    getDeclaringType() instanceof TypeTestNgAssert
    and hasName("expectThrows")
  }

  override
  int getExpectedClassParamIndex() {
    result = 0
  }

  override
  int getExecutableParamIndex() {
    result = 1
  }

  override
  predicate returnsException() {
    any()
  }
}

class TypeTestNgFileAssert extends Class {
  TypeTestNgFileAssert() {
    hasQualifiedName("org.testng", "FileAssert")
  }
}

class TestNgFail extends FailMethod {
  TestNgFail() {
    (
      getDeclaringType() instanceof TypeTestNgAssert
      or getDeclaringType() instanceof TypeTestNgFileAssert
    )
    and hasName("fail")
  }
}

/**
 * A compile time constant expression or any literal.
 */
class CompileTimeConstantOrLiteral extends Expr {
  CompileTimeConstantOrLiteral() {
    // CompileTimeConstantExpr does not include NullLiteral and TypeLiteral
    this instanceof CompileTimeConstantExpr
    or this instanceof NullLiteral
    or this instanceof TypeLiteral
  }
}
