import java

import lib.VarAccess

// TODO: Maybe also consider java.util.concurrent.locks.StampedLock

/**
 * Some form of synchronization which guards zero or more statements.
 */
abstract class Synchronization extends Top {
    /**
     * Holds if this synchronization contains the given expression.
     */
    abstract predicate includesStmt(Stmt stmt);
    
    /**
     * Holds if this synchronization contains the given expression.
     */
    abstract predicate includes(Expr expr);
    
    /**
     * Holds if this synchronization uses the same lock as the other one.
     */
    abstract predicate usesSameLockAs(Synchronization other);
    
    /**
     * Gets a human-readable string describing the kind of synchronization.
     */
    abstract string describe();
}

pragma[inline] // inline this, otherwise this is extremely inefficient
private predicate haveCommonAncestor(RefType a, RefType b) {
    a.getASourceSupertype*() = b.getASourceSupertype*()
}

private class SynchronizedStmt_ extends Synchronization, SynchronizedStmt {
    override predicate includesStmt(Stmt stmt) {
        stmt.getEnclosingStmt().getEnclosingStmt*() = this
    }

    override predicate includes(Expr expr) {
        includesStmt(expr.getEnclosingStmt())
    }
    
    override predicate usesSameLockAs(Synchronization other) {
        haveCommonAncestor(getExpr().(ThisAccess).getType(), other.(SynchronizedStmt_).getExpr().(ThisAccess).getType())
        or haveCommonAncestor(getExpr().(ThisAccess).getType(), other.(SynchronizedMethod).getDeclaringType())
        or accessSameVarOfSameOwner(getExpr(), other.(SynchronizedStmt_).getExpr())
        or getExpr().(TypeLiteral).getType() = other.(SynchronizedStmt).getExpr().(TypeLiteral).getType()
        or getExpr().(TypeLiteral).getType() = other.(SynchronizedStaticMethod).getDeclaringType()
    }
    
    override string describe() {
        result = "synchronized statement"
    }
}

private class SynchronizedMethod extends Synchronization, Method {
    SynchronizedMethod() {
        not isStatic()
        and isSynchronized()
    }
    
    override predicate includesStmt(Stmt stmt) {
        stmt.getEnclosingCallable() = this
    }

    override predicate includes(Expr expr) {
        includesStmt(expr.getEnclosingStmt())
    }
    
    override predicate usesSameLockAs(Synchronization other) {
        haveCommonAncestor(getDeclaringType(), other.(SynchronizedMethod).getDeclaringType())
        // Covers SynchronizedStmt_ checks
        or other.usesSameLockAs(this)
    }
    
    override string describe() {
        result = "synchronized method"
    }
}

private class SynchronizedStaticMethod extends Synchronization, Method {
    SynchronizedStaticMethod() {
        isStatic()
        and isSynchronized()
    }
    
    override predicate includesStmt(Stmt stmt) {
        stmt.getEnclosingCallable() = this
    }

    override predicate includes(Expr expr) {
        includesStmt(expr.getEnclosingStmt())
    }
    
    override predicate usesSameLockAs(Synchronization other) {
        getDeclaringType() = other.(SynchronizedStaticMethod).getDeclaringType()
        // Covers SynchronizedStmt_ checks
        or other.usesSameLockAs(this)
    }
    
    override string describe() {
        result = "synchronized static method"
    }
}

private class TypeLock extends Interface {
    TypeLock() {
        hasQualifiedName("java.util.concurrent.locks", "Lock")
    }
}

private class LockMethod extends Method {
    LockMethod() {
        getAnOverride*().getDeclaringType() instanceof TypeLock
        and hasName(["lock", "lockInterruptibly", "tryLock"])
    }
}

private class UnlockMethod extends Method {
    UnlockMethod() {
        getAnOverride*().getDeclaringType() instanceof TypeLock
        and hasName("unlock")
    }
}

private class TypeReadWriteLock extends Interface {
    TypeReadWriteLock() {
        hasQualifiedName("java.util.concurrent.locks", "ReadWriteLock")
    }
}

private class ReadLockMethod extends Method {
    ReadLockMethod() {
        getAnOverride*().getDeclaringType() instanceof TypeReadWriteLock
        and hasName("readLock")
    }
}

private class WriteLockMethod extends Method {
    WriteLockMethod() {
        getAnOverride*().getDeclaringType() instanceof TypeReadWriteLock
        and hasName("writeLock")
    }
}

private class LockMethodCalls extends Synchronization, MethodAccess {
    LockMethodCalls() {
        getMethod() instanceof LockMethod
    }

    private predicate isSameLock(Expr a, Expr b) {
        accessSameVarOfSameOwner(a, b)
        // Or usage of ReadWriteLock locks
        or exists(Method readWriteLockGetter |
            readWriteLockGetter instanceof ReadLockMethod
            or readWriteLockGetter instanceof WriteLockMethod
        |
            a.(MethodAccess).getMethod() = readWriteLockGetter
            and b.(MethodAccess).getMethod() = readWriteLockGetter
            and accessSameVarOfSameOwner(a.(MethodAccess).getQualifier(), b.(MethodAccess).getQualifier())
        )
    }
    
    override predicate includesStmt(Stmt stmt) {
        exists (MethodAccess unlockCall |
            unlockCall.getMethod() instanceof UnlockMethod
            and isSameLock(getQualifier(), unlockCall.getQualifier())
        |
            this.getControlFlowNode().getASuccessor+() = stmt
            and stmt.getControlFlowNode().getASuccessor+() = unlockCall
        )
    }

    override predicate includes(Expr expr) {
        exists (MethodAccess unlockCall |
            unlockCall.getMethod() instanceof UnlockMethod
            and isSameLock(getQualifier(), unlockCall.getQualifier())
        |
            this.getControlFlowNode().getASuccessor+() = expr
            and expr.getControlFlowNode().getASuccessor+() = unlockCall
        )
    }
    
    override predicate usesSameLockAs(Synchronization other) {
        isSameLock(getQualifier(), other.(LockMethodCalls).getQualifier())
    }
    
    override string describe() {
        if hasQualifier() then (
            result = "lock on " + getQualifier()
        ) else (
            result = "own lock methods"
        )
    }
}

/**
 * Some kind of statement which marks the start of a synchronized section, or the complete
 * synchronized section (in case of `synchronized` statements).
 */
class SynchronizationStatement extends Synchronization, Stmt {
    Synchronization delegate;

    SynchronizationStatement() {
        delegate.(SynchronizedStmt_) = this
        or
        delegate.(LockMethodCalls).getEnclosingStmt() = this
    }

    override predicate includesStmt(Stmt stmt) {
        delegate.includesStmt(stmt)
    }

    override predicate includes(Expr expr) {
        delegate.includes(expr)
    }
    
    override predicate usesSameLockAs(Synchronization other) {
        delegate.usesSameLockAs(other)
    }
    
    override string describe() {
        result = delegate.describe()
    }
}

/**
 * Holds if the expression is synchronized by the specified synchronization, or a
 * synchronization which uses the same lock.
 */
predicate isExprSynchronizedBy(Expr expr, Synchronization synchronization) {
    synchronization.includes(expr)
    or exists (Synchronization other | other.usesSameLockAs(synchronization) |
        other.includes(expr)
    )
}

predicate isExprSynchronized(Expr e) {
    isExprSynchronizedBy(e, _)
}

/**
 * Holds if safe publication is required for instances of the class to ensure that other
 * threads see an up-to-date version of the instances.
 * 
 * See also [JLS: `final` Field Semantics](https://docs.oracle.com/javase/specs/jls/se17/html/jls-17.html#jls-17.5)
 */
predicate requiresSafePublication(Class c) {
    exists (Field f | f = c.getAField() |
        not f.isStatic()
        and not (f.isFinal() or f.isVolatile())
    )
    or exists (RefType superType | superType = c.getASourceSupertype() |
        requiresSafePublication(superType)
    )
}
