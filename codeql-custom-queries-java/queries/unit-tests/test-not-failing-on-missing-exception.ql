/**
 * Tries to find test methods which are expecting an exception and perform
 * this assertion using a try-catch statement, but do not fail if no exception
 * is thrown.
 */

import java
import lib.TestsQLInterop

predicate isTestMethod(Callable callable) {
    (
        callable instanceof TestMethod
        // Check if method is inside test class, might be utility method
        // then which is used by test methods
        or exists (RefType type | type = callable.getDeclaringType() |
            type instanceof TestClass
            and type.isTopLevel()
            and type.getCompilationUnit() = callable.getCompilationUnit()
        )
    )
    // Ignore teardown methods
    and not callable instanceof TeardownMethod
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

predicate isFailing(BlockStmt tryBlock) {
    exists(TestFailingCall failCall, ExprStmt failCallStmt |
        failCall.getEnclosingStmt() = failCallStmt
        // Fail call should be last statement
        and tryBlock.getLastStmt() = failCallStmt
    )
}

from TryStmt try
where
    isTestMethod(try.getEnclosingCallable())
    and isExpectingException(try.getACatchClause())
    and not isFailing(try.getBlock())
select try, "Test does not fail when the expected exception is not thrown in this `try` statement"
