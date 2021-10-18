/**
 * Finds unreachable code after assertion calls which always fail, such as `fail()`.
 */

import java
import lib.TestsQLInterop
import lib.TestNg

from TestFailingCall testFailingCall, Stmt successor
where
  strictlyDominates(testFailingCall, successor)
  // Ignore statements which are used to indicate to the compiler that execution ends
  and not (
    successor instanceof ReturnStmt
    or successor instanceof ThrowStmt
    or successor instanceof BreakStmt
    or successor instanceof ContinueStmt
  )
  // Ignore SoftAssert which does not fail immediately
  and not testFailingCall.getMethod().getDeclaringType() instanceof TestNgSoftAssert
select successor, "Unreachable due to $@ failing assertion call", testFailingCall, "this"
