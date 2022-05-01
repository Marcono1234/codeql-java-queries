/**
 * Finds calls to `Thread.interrupted()` after which the interrupt status is not restored.
 * `interrupted()` clears the status and returns the previous value. Callers should therefore
 * either set the interrupt status again by calling `interrupt()` (or call `isInterrupted()`
 * in the first place, which does not clear the status) or throw an exception indicating the
 * interrupt, e.g. `InterruptedException`.
 */

import java
import lib.Expressions

class TypeThread extends Class {
    TypeThread() {
        hasQualifiedName("java.lang", "Thread")
    }
}

class InterruptedMethod extends Method {
    InterruptedMethod() {
        getDeclaringType() instanceof TypeThread
        and hasStringSignature("interrupted()")
    }
}

class InterruptMethod extends Method {
    InterruptMethod() {
        getDeclaringType() instanceof TypeThread
        and hasStringSignature("interrupt()")
    }
}

class InterruptedExceptionType extends Class {
    InterruptedExceptionType() {
        hasQualifiedName("java.lang", "InterruptedException")
        or hasQualifiedName("java.io", "InterruptedIOException")
    }
}

from MethodAccess interruptedCall
where
    interruptedCall.getMethod() instanceof InterruptedMethod
    and
    (
        // Result is discarded
        interruptedCall instanceof ValueDiscardingExpr
        // Or interrupt status is not restored
        or
        not exists(ExprParent interruptRestoringElement |
            interruptedCall.getControlFlowNode().getASuccessor+() = interruptRestoringElement
        |
            interruptRestoringElement.(MethodAccess).getMethod() instanceof InterruptMethod
            or interruptRestoringElement.(ThrowStmt).getThrownExceptionType().getASourceSupertype*() instanceof InterruptedExceptionType
        )
        // And is not inside run() method; then it might be termination check for a thread task
        and not exists(Method runMethod |
            runMethod = interruptedCall.getEnclosingCallable()
            and runMethod.getDeclaringType().getASourceSupertype().hasQualifiedName("java.lang", "Runnable")
            and runMethod.hasStringSignature("run()")
        )
    )
select interruptedCall, "Clears interrupted status but does not restore it again with `interrupt()` call"
