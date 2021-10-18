/**
 * Finds `try-catch` statements which catch an exception and then manually cause a
 * test failure. Such code is redundant; the test framework will treat any thrown
 * exceptions as test failure, there is no need to manually trigger this.
 */

import java
import lib.TestsQLInterop

from TryStmt tryStmt, CatchClause catchClause, TestFailingCall failingCall
where
    tryStmt.getEnclosingCallable() instanceof TestMethod
    and catchClause = tryStmt.getACatchClause()
    // Failing call is directly inside catch block (and not nested)
    and failingCall.getEnclosingStmt() = catchClause.getBlock().getAStmt()
    // Ignore if failing call has custom failure message
    and not failingCall.getAnArgument().getType() instanceof TypeString
select catchClause, "Should remove this `catch` clause which manually causes test failure $@ on exception", failingCall, "here"
