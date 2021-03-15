/**
 * Finds statements which appear after a call to `System.exit(int)`,
 * `Runtime.exit(int)` or `Runtime.halt(int)`.
 * These methods never return, therefore any statements after them
 * are effectively dead code.
 */
// Note that this is also detected (among others) by semmle.code.java.controlflow.UnreachableBlocks

import java

class ExitingMethod extends Method {
    ExitingMethod() {
        (
            getDeclaringType() instanceof TypeSystem
            and hasStringSignature("exit(int)")
        )
        or (
            getDeclaringType() instanceof TypeRuntime
            and hasStringSignature(["exit(int)", "halt(int)"])
        )
    }
}

from MethodAccess exitingCall, Stmt exitingStmt, Stmt otherStmt
where
    exitingCall.getMethod() instanceof ExitingMethod
    and exitingStmt = exitingCall.getEnclosingStmt()
    and otherStmt != exitingStmt
    // Make sure statements have the same parent
    // Otherwise other statement might be reachable, e.g. when exiting call is
    // only performed conditionally (therefore having different parent)
    // (Might still yield false positives for statements in separate switch-cases)
    and otherStmt.getParent() = exitingStmt.getParent()
    // return or throw statement is necessary in some cases to prevent compilation failure
    and not (otherStmt instanceof ReturnStmt or otherStmt instanceof ThrowStmt)
    // Have to check index because control flow apparently considers that these
    // methods don't return
    and exitingStmt.getIndex() < otherStmt.getIndex()
select otherStmt, "Unreachable statement because JVM exiting call $@ never returns", exitingCall, "here"
