import java
import AssertLib

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
