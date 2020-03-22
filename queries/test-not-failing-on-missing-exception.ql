/**
 * Tries to find test methods which are expecting an exception and perform
 * this assertion using a try-catch statement, but do not fail if no exception
 * is thrown.
 */

import java
import semmle.code.java.frameworks.Assertions

predicate isTearDownMethod(Callable callable) {
    callable instanceof TearDownMethod // Only covers JUnit 3.8
    // JUnit 4
    or callable.hasAnnotation("org.junit", "After")
    or callable.hasAnnotation("org.junit", "AfterClass")
    // JUnit 5
    or callable.hasAnnotation("org.junit.jupiter.api", "AfterEach")
    or callable.hasAnnotation("org.junit.jupiter.api", "AfterAll")
}

predicate isTestMethod(Callable callable) {
    ( 
        callable instanceof TestMethod
        // TestMethod currently does not cover JUnit 5, check it manually
        or callable.hasAnnotation("org.junit.jupiter.api", "Test")
        // Check if method is inside test class, might be utility method
        // then which is used by test methods
        or exists (RefType type | type = callable.getDeclaringType() |
            type instanceof TestClass
            and type.isTopLevel()
            and type.getCompilationUnit() = callable.getCompilationUnit()
        )
    )
    // Ignore tearDown methods
    and not isTearDownMethod(callable)
}

predicate isExpectingException(CatchClause catch) {
    // Usually block is empty when exception is expected
    catch.getBlock().getNumStmt() = 0 
    // Or it performs assertions on the expected exception
    or exists(MethodAccess assertCall |
        assertCall.getEnclosingStmt() = catch
        and assertCall.getMethod() instanceof AssertionMethod
    )
}

predicate isFailMethodCall(MethodAccess call, Method m) {
    m instanceof AssertFailMethod
    // AssertFailMethod currently does not cover JUnit 5, check it manually
    or (m.hasName("fail") and m.getDeclaringType().hasQualifiedName("org.junit.jupiter.api", "Assertions"))
    // Sometimes these tests also fail by calling assertTrue(false) / assertFalse(true)
    or (
        m.hasName("assertTrue")
        and call.getAnArgument().(BooleanLiteral).getBooleanValue() = false
    )
    or (
        m.hasName("assertFalse")
        and call.getAnArgument().(BooleanLiteral).getBooleanValue() = true
    )
}

predicate isFailing(Block tryBlock) {
    exists(MethodAccess failCall, ExprStmt failCallStmt |
        isFailMethodCall(failCall, failCall.getMethod())
        and failCall.getEnclosingStmt() = failCallStmt
        // Fail call should be last statement
        and tryBlock.getLastStmt() = failCallStmt
    )
}

from TryStmt try
where
    isTestMethod(try.getEnclosingCallable())
    and isExpectingException(try.getACatchClause())
    and not isFailing(try.getBlock())
select try
