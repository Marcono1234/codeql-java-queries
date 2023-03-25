/**
 * Finds test methods which use `try`-`catch` to check for an expected exception,
 * but where the `try` block contains a pointless assertion. For example:
 * ```java
 * try {
 *     // assertEquals is pointless because code should have already failed with
 *     // expected exception, and if not it would reach `fail()` call below
 *     assertEquals(3, parseInt("invalid"));
 *     fail();
 * } catch (IllegalArgumentException expected) {
 * }
 * ```
 * 
 * @kind problem
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

from TryStmt try, BlockStmt tryBlock, MethodAccess assertCall, AssertionMethod assertMethod
where
    isTestMethod(try.getEnclosingCallable())
    and tryBlock = try.getBlock()
    and isExpectingException(try.getACatchClause())
    and assertCall.getAnEnclosingStmt() = tryBlock
    and assertMethod = assertCall.getMethod()
    and not assertMethod instanceof AssertFailMethod
    and not assertCall instanceof TestFailingCall
    and exists(ExprStmt assertCallStmt, ExprStmt failCallStmt |
        assertCallStmt.getExpr() = assertCall
        and assertCallStmt.getEnclosingStmt+() = tryBlock
        and failCallStmt.getExpr() instanceof TestFailingCall
        // Fail call should be last statement
        and tryBlock.getLastStmt() = failCallStmt
        // And assert call should come immediately before failing call, to reduce false positives
        // for cases where assert call occurs before call which is causing the expected exception
        and assertCallStmt.getIndex() + 1 = failCallStmt.getIndex()
    )
select assertCall, "Assertion call is pointless because code should have already failed with expected exception"
