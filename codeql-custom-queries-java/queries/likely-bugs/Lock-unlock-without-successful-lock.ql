/**
 * Finds paths where a `java.util.concurrent.locks.Lock` is unlocked without
 * it having been acquired successfully before. This can break synchronization
 * on resources. E.g.:
 * ```
 * try {
 *     // Bad: If an exception is thrown here (and lock was not successfully
 *     // acquired) it will be released in `finally` nonetheless
 *     lock.lock();
 * }
 * finally {
 *     lock.unlock();
 * }
 * ```
 *
 * @kind path-problem
 */

// Similar to CodeQL's `java/unreleased-lock`

/*
 * Created with the help of:
 * - https://github.com/github/codeql/discussions/5353#discussioncomment-439461
 * - https://github.blog/2021-02-25-the-little-bug-that-couldnt-securing-openssl/#finding-all-the-bug-variants
 */

import java

// TODO: Reduce code duplication; already declared in lib.ConcurrencyLib.qll
class TypeLock extends Interface {
    TypeLock() {
        hasQualifiedName("java.util.concurrent.locks", "Lock")
    }
}

class LockMethod extends Method {
    LockMethod() {
        getAnOverride*().getDeclaringType() instanceof TypeLock
        and hasName(["lock", "lockInterruptibly", "tryLock"])
    }

    predicate returnsTrueOnSuccess() {
        hasName("tryLock")
    }
}

class LockingCall extends MethodAccess {
    LockingCall() {
        getMethod() instanceof LockMethod
    }

    ControlFlowNode getALockedSuccessor() {
        if getMethod().(LockMethod).returnsTrueOnSuccess()
        then (
            // Only consider if there is a condition node; otherwise call might not have actually locked
            exists(ConditionNode condition |
                condition.getCondition() = this
                and result = condition.getATrueSuccessor()
            )
            // Or result is stored somewhere, assuming it is used later on
            or any(AssignExpr a).getRhs() = this
        )
        // Lock method does not require result check
        else result = getControlFlowNode().getASuccessor()
    }
}

class TypeReentrantLock extends Class {
    TypeReentrantLock() {
        hasQualifiedName("java.util.concurrent.locks", "ReentrantLock")
    }
}

class IsHeldByCurrentThreadMethod extends Method {
    IsHeldByCurrentThreadMethod() {
        getDeclaringType().getASourceSupertype*() instanceof TypeReentrantLock
        and hasStringSignature("isHeldByCurrentThread()")
    }
}

class UnlockMethod extends Method {
    UnlockMethod() {
        getAnOverride*().getDeclaringType() instanceof TypeLock
        and hasName("unlock")
    }
}

class UnlockingCall extends MethodAccess {
    UnlockingCall() {
        getMethod() instanceof UnlockMethod
    }
}

// TODO: If possible exclude redundant ControlFlowNodes from displayed path explanation
query predicate edges(ControlFlowNode a, ControlFlowNode b) {
    a.getASuccessor() = b
    // TODO: Ideally also verify that calls are made on same receiver,
    //       but this might not be possible using `edges` predicate?
    // Ignore if there occurs a locking call before unlocking
    and not exists(LockingCall lockingCall |
        lockingCall.getControlFlowNode() = a
        and lockingCall.getALockedSuccessor() = b
    )
    // Ignore if there occurs a lock holding check before unlocking
    // TODO: Does not cover calls to ReentrantReadWriteLock and nested type methods
    and not exists(MethodAccess holdingLockCheck, ConditionNode condition |
        holdingLockCheck.getMethod() instanceof IsHeldByCurrentThreadMethod
        and holdingLockCheck.getControlFlowNode() = a
        and condition.getCondition() = holdingLockCheck
        and condition.getATrueSuccessor() = b
    )
}

from Callable callable, ControlFlowNode entryNode, ControlFlowNode unlockingNode
where
    entryNode = callable.getBody().getBasicBlock().getFirstNode()
    and unlockingNode = any(UnlockingCall c).getControlFlowNode()
    // Only consider methods which perform locking; ignore ones which only unlock
    and any(LockingCall c).getEnclosingCallable() = callable
    and edges+(entryNode, unlockingNode)
select unlockingNode, entryNode, unlockingNode, "Releases lock without having acquired it successfully"
