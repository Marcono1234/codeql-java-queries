import java
import AssertLib

abstract class JUnit3AssertionMethod extends Method {
}

// Note: These classes are also part of JUnit 4, where Assert is deprecated and
// TestCase re-implements the assertion methods
class TypeJUnit3AssertOrTestCase extends Class {
  TypeJUnit3AssertOrTestCase() {
    this instanceof TypeJUnitTestCase
    or hasQualifiedName("junit.framework", "Assert")
    // TestNG has an AssertJUnit class which might seems to originate from JUnit 3
    // for simplicity pretend it is a JUnit 3 Assert class
    or hasQualifiedName("org.testng", "AssertJUnit")
  }
}

class JUnit3AssertTrue extends AssertTrueMethod, JUnit3AssertionMethod {
  JUnit3AssertTrue() {
    getDeclaringType() instanceof TypeJUnit3AssertOrTestCase
    and hasName("assertTrue")
  }

  override
  int getAssertionParamIndex() {
    result = getNumberOfParameters() - 1
  }
}

class JUnit3AssertFalse extends AssertFalseMethod, JUnit3AssertionMethod {
  JUnit3AssertFalse() {
    getDeclaringType() instanceof TypeJUnit3AssertOrTestCase
    and hasName("assertFalse")
  }

  override
  int getAssertionParamIndex() {
    result = getNumberOfParameters() - 1
  }
}

class JUnit3AssertNull extends AssertNullMethod, JUnit3AssertionMethod {
  JUnit3AssertNull() {
    getDeclaringType() instanceof TypeJUnit3AssertOrTestCase
    and hasName("assertNull")
  }

  override
  int getAssertionParamIndex() {
    result = getNumberOfParameters() - 1
  }
}

class JUnit3AssertNotNull extends AssertNotNullMethod, JUnit3AssertionMethod {
  JUnit3AssertNotNull() {
    getDeclaringType() instanceof TypeJUnit3AssertOrTestCase
    and hasName("assertNotNull")
  }

  override
  int getAssertionParamIndex() {
    result = getNumberOfParameters() - 1
  }
}

class JUnit3AssertEquals extends AssertEqualsMethod, JUnit3AssertionMethod {
  int messageOffset;

  JUnit3AssertEquals() {
    getDeclaringType() instanceof TypeJUnit3AssertOrTestCase
    and hasName("assertEquals")
    // Also have to check parameter count because there is `assertEquals(String, String)`
    and if (getParameterType(0) instanceof TypeString and getNumberOfParameters() > 2)
    then messageOffset = 1
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
    // TestNG's AssertJUnit has two `assertEquals` methods taking a `byte[]`
    getParameterType(getFixedParamIndex()) instanceof Array and deepEquals = false
  }
}

class JUnit3AssertSame extends AssertSameMethod, JUnit3AssertionMethod {
  int messageOffset;

  JUnit3AssertSame() {
    getDeclaringType() instanceof TypeJUnit3AssertOrTestCase
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

class JUnit3AssertNotSame extends AssertNotSameMethod, JUnit3AssertionMethod {
  int messageOffset;

  JUnit3AssertNotSame() {
    getDeclaringType() instanceof TypeJUnit3AssertOrTestCase
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

class JUnit3Fail extends FailMethod, JUnit3AssertionMethod {
  JUnit3Fail() {
    getDeclaringType() instanceof TypeJUnit3AssertOrTestCase
    and hasName("fail")
  }
}
