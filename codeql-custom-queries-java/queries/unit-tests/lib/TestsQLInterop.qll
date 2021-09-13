/**
 * Library which combines existing CodeQL classes with classes added by custom
 * libraries in this folder.
 */

import java
private import semmle.code.java.frameworks.Assertions as QL
private import AssertLib
private import Tests
private import JUnit5

class AssertionMethod extends Method {
    AssertionMethod() {
        (
            this instanceof QL::AssertionMethod
            // CodeQL's class also matches non unit test related methods; exclude them
            and not this.getDeclaringType().getPackage().getName().matches([
                "java.%",
                "com.google.common.base"
            ])
        )
        or this instanceof AssertMethod
    }
}

class AssertFailMethod extends Method {
    AssertFailMethod() {
        this instanceof QL::AssertFailMethod
        or this instanceof FailMethod
    }
}

/**
 * Call which will cause a test failure.
 */
class TestFailingCall extends MethodAccess {
    TestFailingCall() {
        exists(Method m | m = getMethod() |
            m instanceof AssertFailMethod
            // Sometimes these tests also fail by calling assertTrue(false) / assertFalse(true)
            or (
                m.hasName("assertTrue")
                and getAnArgument().(BooleanLiteral).getBooleanValue() = false
            )
            or (
                m.hasName("assertFalse")
                and getAnArgument().(BooleanLiteral).getBooleanValue() = true
            )
        )
    }
}

class TeardownMethod extends Method {
    TeardownMethod() {
        this instanceof TeardownMethod // Only covers JUnit 3.8
        or getAnAnnotation().getType() instanceof TeardownAnnotationType
    }
}

/**
 * A statement which exits a test method, either by throwing an exception or
 * by returning (e.g. to skip a following `fail()` call).
 */
class TestExitingStmt extends Stmt {
    TestExitingStmt() {
        this.(ExprStmt).getExpr() instanceof TestFailingCall
        or this instanceof ThrowStmt
        or this instanceof ReturnStmt
    }

    /** Whether this statement causes a test success. */
    predicate causesTestSuccess() {
        this instanceof ReturnStmt
    }
}
