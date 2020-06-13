/**
 * Finds assertion method calls in the form `assertTrue(false)` or `assertFalse(true)`
 * despite there being a `fail` method offered by the assertion class.
 * The `fail` method should be preferred because the desired outcome for it is clearer.
 */

import java

class AssertClass extends Class {
    AssertClass() {
        getQualifiedName() in [
            "org.junit.Assert", // JUnit 4
            "org.junit.jupiter.api.Assertions", // JUnit 5
            "org.testng.Assert" // TestNG
        ]
    }
}

class AssertTrueMethod extends Method {
    AssertTrueMethod() {
        hasStringSignature("assertTrue(boolean)")
        and getDeclaringType() instanceof AssertClass
    }
}

class AssertFalseMethod extends Method {
    AssertFalseMethod() {
        hasStringSignature("assertFalse(boolean)")
        and getDeclaringType() instanceof AssertClass
    }
}

from MethodAccess assertCall, Method assertMethod, boolean firstArgumentValue
where
    assertMethod = assertCall.getMethod()
    and firstArgumentValue = assertCall.getArgument(0).(BooleanLiteral).getBooleanValue()
    and (
        firstArgumentValue = false and assertMethod instanceof AssertTrueMethod
        or firstArgumentValue = true and assertMethod instanceof AssertFalseMethod
    )
select assertCall
