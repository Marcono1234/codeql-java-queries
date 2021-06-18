/**
 * Finds `return` statements in unit test methods. Such statements will skip
 * subsequent checks of the test method, which might not be intended.
 * E.g.:
 * ```java
 * @Test
 * void testSingletonList() {
 *     List<?> list = Collections.singletonList​("value");
 *     try {
 *         list.clear();
 *         fail("Expected exception");
 *     } catch (UnsupportedOperationException e) {
 *         assertEquals(..., e.getMessage());
 *         // Skips subsequent checks
 *         return;
 *     }
 * 
 *     // This is never executed
 *     assertEquals(1, list.size());
 * }
 * ```
 */

import java
import semmle.code.java.frameworks.Assertions

StmtParent getParent(Stmt s) {
    result = s.getParent()
    // Skip BlockStmt
    or result = getParent(s.getParent().(BlockStmt))
}

/** Statement which causes a test to fail */
class TestFailingStmt extends Stmt {
    TestFailingStmt() {
        this instanceof ThrowStmt
        or this.(ExprStmt).getExpr().(MethodAccess).getMethod() instanceof AssertFailMethod
    }
}

from ReturnStmt returnStmt
where
    returnStmt.getEnclosingCallable() instanceof TestMethod
    // Ignore if returnStmt is guarded by `if` statement, might be a precondition check
    and not any(IfStmt s) = getParent(returnStmt)
    // Ignore if returnStmt is executed when expected exception is caught and subsequent code
    // is intended to handle missing exception, e.g. `try { ... } catch (...) { return; } fail();`
    and not exists(TryStmt tryStmt, TestFailingStmt failingStmt |
        tryStmt.getACatchClause().getBlock() = returnStmt.getEnclosingStmt()
        and strictlyDominates(tryStmt.getControlFlowNode(), failingStmt.getControlFlowNode())
    )
select returnStmt, "`return` statement might skip subsequent checks of test method"
