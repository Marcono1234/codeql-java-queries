/**
 * Finds calls to `Thread.currentThread().interrupt()` after which iteration in a loop continues
 * and might again call a method which throws an exception when interrupted. This can cause high
 * CPU usage because the thread continuously keeps interrupting itself. For example:
 * ```java
 * while (...) {
 *     try {
 *         ...
 * 
 *         lock.wait();
 *     } catch (InterruptedException e) {
 *         // Bad: interrupt() call inside loop will cause subsequent wait() call to directly
 *         // throw exception again
 *         Thread.currentThread().interrupt();
 *     }
 * }
 * ```
 * 
 * Instead, either handling for `InterruptedException` should be moved outside the loop, the loop
 * should be exited when an `InterruptedException` is encountered, or a boolean variable should
 * be set and the interrupt status should be restored outside the loop.
 */

 /*
  * TODO: Maybe also consider catching java.nio.channels.ClosedByInterruptException or java.nio.channels.FileLockInterruptionException
  * (for which the interrupt status is set) in a loop without breaking the loop
  */

import java

class TypeThread extends Class {
    TypeThread() {
        hasQualifiedName("java.lang", "Thread")
    }
}

/**
 * A call to `Thread.currentThread().interrupt()`.
 */
class CurrentThreadInterruptCall extends MethodAccess {
    CurrentThreadInterruptCall() {
        exists(Method interruptMethod, Method currentThreadMethod |
            interruptMethod = getMethod()
            and interruptMethod.getDeclaringType() instanceof TypeThread
            and interruptMethod.hasStringSignature("interrupt()")
            // Qualifier is Thread.currentThread() call
            and currentThreadMethod = getQualifier().(MethodAccess).getMethod()
            and currentThreadMethod.getDeclaringType() instanceof TypeThread
            and currentThreadMethod.hasStringSignature("currentThread()")
        )
    }
}

class InterruptedQueryMethod extends Method {
    InterruptedQueryMethod() {
        getDeclaringType() instanceof TypeThread
        and hasStringSignature(["interrupted()", "isInterrupted()"])
    }
}

class InterruptedExceptionType extends Class {
    InterruptedExceptionType() {
        hasQualifiedName("java.lang", "InterruptedException")
        or hasQualifiedName("java.io", "InterruptedIOException")
    }
}

predicate isPotentiallyCatchingInterruptedException(TryStmt tryStmt) {
    exists(RefType caughtType | caughtType = tryStmt.getACatchClause().getACaughtType() |
        // Either catches interrupted exception type (or subtype), or a more generic supertype such as Exception
        caughtType.getASourceSupertype*() = any(InterruptedExceptionType t).getASourceSupertype*()
    )
}

from LoopStmt loop, CurrentThreadInterruptCall interruptCall, TryStmt tryStmt
where
    loop.getBody() = tryStmt.getEnclosingStmt*()
    and isPotentiallyCatchingInterruptedException(tryStmt)
    and interruptCall.getAnEnclosingStmt() = loop.getBody()
    // Ignore loops where iteration is limited
    and not (
        loop instanceof EnhancedForStmt
        or exists(loop.(ForStmt).getAnUpdate())
    )
    // interrupt() call happens after expression in `try` body
    and dominates(tryStmt.getBlock().getAChild().getControlFlowNode(), interruptCall.getControlFlowNode())
    // And interrupt call is not inside try
    and not interruptCall.getAnEnclosingStmt() = tryStmt.getBlock()
    // TODO: Make this more specific, but control flow might yield wrong results due to loop iterations
    and not exists(Stmt breakingStmt |
        breakingStmt.getEnclosingStmt+() = interruptCall.getEnclosingStmt().getEnclosingStmt()
    |
        breakingStmt instanceof ThrowStmt
        or breakingStmt instanceof ReturnStmt
        // Or break statement which breaks loop or enclosing statement
        or breakingStmt.(BreakStmt).(JumpStmt).getTarget() = loop.getParent*()
        // Or sets a flag (local variable or field) which might affect loop iteration
        or breakingStmt.(ExprStmt).getExpr().(AssignExpr).getType() instanceof BooleanType
    )
    and not loop.getCondition().getAChildExpr+().(MethodAccess).getMethod() instanceof InterruptedQueryMethod
select interruptCall, "interrupt() call inside $@ loop might cause excessive CPU usage", loop, "this"
