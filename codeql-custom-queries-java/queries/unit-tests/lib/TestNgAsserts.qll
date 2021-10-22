import java
import AssertLib

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
