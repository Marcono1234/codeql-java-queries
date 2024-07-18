import java

import JUnit3Asserts
import JUnit4Asserts
import JUnit5Asserts
import TestNgAsserts

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
  abstract boolean expectedBooleanValue();
}

abstract class AssertTrueMethod extends AssertBooleanMethod {
  override
  boolean expectedBooleanValue() {
    result = true
  }
}

abstract class AssertFalseMethod extends AssertBooleanMethod {
  override
  boolean expectedBooleanValue() {
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

/**
 * An expression with constant value.
 */
class ConstantExpr extends Expr {
  ConstantExpr() {
    // CompileTimeConstantExpr does not include NullLiteral and TypeLiteral
    this instanceof CompileTimeConstantExpr
    or
    this instanceof NullLiteral
    or
    this instanceof TypeLiteral
    or
    this.(FieldRead).getField() instanceof EnumConstant
    or
    exists(Field f |
      f = this.(FieldRead).getField() and
      f.isStatic() and
      f.isFinal() and
      // And field is declared in third-party library or JDK, otherwise test might intentionally
      // use constant as 'actual' argument to check its value
      not f.fromSource()
    )
  }
}
