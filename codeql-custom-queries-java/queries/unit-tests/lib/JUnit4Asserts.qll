import java
import AssertLib

abstract class JUnit4AssertionMethod extends Method {
}

class TypeJUnit4Assert extends Class {
  TypeJUnit4Assert() {
    hasQualifiedName("org.junit", "Assert")
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
