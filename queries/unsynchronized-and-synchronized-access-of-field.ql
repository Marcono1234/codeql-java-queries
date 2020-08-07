/**
 * Finds unsynchronized access to a field which is accessed in a
 * synchronized way at a different location. This indicates that
 * the declaring class is intended for concurrent use, however due
 * to one access not being synchronized the Java Memory Model does
 * not guarantee any thread-safety.
 * Example:
 * ```
 * class CountingContainer {
 *     private Map<String, Integer> storage;
 *
 *     public synchronized void add(String s) {
 *         storage.merge(s, 1, (oldCount, newCount) -> oldCount + newCount);
 *     }
 *
 *     // Method is not synchronized; call from different thread causes undefined behavior
 *     public boolean contains(String s) {
 *         return storage.containsKey(s);
 *     }
 * }
 * ```
 */

import java
import semmle.code.java.dataflow.DataFlow

abstract class Synchronization extends Top {
    abstract predicate includesStmt(Stmt stmt);
    
    predicate includes(Expr expr) {
        includesStmt(expr.getEnclosingStmt())
    }
    
    abstract predicate synchronizesOnSameAs(Synchronization other);
    
    abstract string describe();
}

predicate haveCommonAncestor(RefType a, RefType b) {
    a.getASourceSupertype*() = b.getASourceSupertype*()
}

class SynchronizedStmt_ extends Synchronization, SynchronizedStmt {
    override predicate includesStmt(Stmt stmt) {
        stmt.getEnclosingStmt().getEnclosingStmt*() = this
    }
    
    override predicate synchronizesOnSameAs(Synchronization other) {
        haveCommonAncestor(getExpr().(ThisAccess).getType(), other.(SynchronizedStmt_).getExpr().getType())
        or haveCommonAncestor(getExpr().(ThisAccess).getType(), other.(SynchronizedMethod).getDeclaringType())
        or accessSameField(getExpr(), other.(SynchronizedStmt_).getExpr())
        or getExpr().(TypeLiteral).getType() = other.(SynchronizedStmt).getExpr().(TypeLiteral).getType()
        or getExpr().(TypeLiteral).getType() = other.(SynchronizedStaticMethod).getDeclaringType()
    }
    
    override string describe() {
        result = "synchronized statement"
    }
}

class SynchronizedMethod extends Synchronization, Method {
    SynchronizedMethod() {
        not isStatic()
        and isSynchronized()
    }
    
    override predicate includesStmt(Stmt stmt) {
        stmt.getEnclosingCallable() = this
    }
    
    override predicate synchronizesOnSameAs(Synchronization other) {
        haveCommonAncestor(getDeclaringType(), other.(SynchronizedMethod).getDeclaringType())
        or other.synchronizesOnSameAs(this)
    }
    
    override string describe() {
        result = "synchronized method"
    }
}

class SynchronizedStaticMethod extends Synchronization, Method {
    SynchronizedStaticMethod() {
        isStatic()
        and isSynchronized()
    }
    
    override predicate includesStmt(Stmt stmt) {
        stmt.getEnclosingCallable() = this
    }
    
    override predicate synchronizesOnSameAs(Synchronization other) {
        getDeclaringType() = other.(SynchronizedStaticMethod).getDeclaringType()
        or other.synchronizesOnSameAs(this)
    }
    
    override string describe() {
        result = "synchronized static method"
    }
}

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
}

class UnlockMethod extends Method {
    UnlockMethod() {
        getAnOverride*().getDeclaringType() instanceof TypeLock
        and hasName("unlock")
    }
}

class LockMethodCalls extends Synchronization, MethodAccess {
    LockMethodCalls() {
        getMethod() instanceof LockMethod
    }
    
    override predicate includesStmt(Stmt stmt) {
        exists (MethodAccess unlockCall |
            unlockCall.getMethod() instanceof UnlockMethod
            and accessSameField(getQualifier(), unlockCall.getQualifier())
        |
            this.getControlFlowNode().getASuccessor+() = stmt
            and stmt.getControlFlowNode().getASuccessor+() = unlockCall
        )
    }
    
    override predicate synchronizesOnSameAs(Synchronization other) {
        accessSameField(getQualifier(), other.(LockMethodCalls).getQualifier())
    }
    
    override string describe() {
        if hasQualifier() then (
            result = "lock on " + getQualifier()
        ) else (
            result = "own lock methods"
        )
    }
}

predicate accessSameField(FieldAccess a, FieldAccess b) {
    a.getField() = b.getField()
    and (
        a.getField().isStatic()
        or a.isOwnFieldAccess() and b.isOwnFieldAccess()
        or exists (RefType enclosing |
            (a.isOwnFieldAccess() or a.isEnclosingFieldAccess(enclosing))
            and (b.isOwnFieldAccess() or b.isEnclosingFieldAccess(enclosing))
        )
        // Don't consider field access with qualifier
    )
}

predicate isPubliclyVisible(RefType t) {
    t.isPublic()
    and (
        not exists (t.getEnclosingType())
        or isPubliclyVisible(t.getEnclosingType())
    )
}

/**
 * Holds if the callable can be called in an unsafe way, not using the `synchronization`.
 * This is either the case when it is publicly visible and therefore no guarantees can be
 * made about usage by different libraries, or if the callable can be called transitively
 * from a publicly visible method.
 */
predicate canBeCalledUnsafely(Callable callable, Synchronization synchronization) {
    (
        isPubliclyVisible(callable.getDeclaringType())
        and (callable.isPublic() or callable.isProtected())
    )
    or exists (Call call | call.getCallee() = callable |
        not exists (Synchronization other |
            other.includes(call)
            and other.synchronizesOnSameAs(synchronization)
        )
        and canBeCalledUnsafely(call.getCaller(), synchronization)
    )
}

predicate isAccessGuardedBy(FieldAccess access, Synchronization synchronization) {
    synchronization.includes(access)
    or exists (Synchronization other | other.synchronizesOnSameAs(synchronization) |
        other.includes(access)
    )
    or not canBeCalledUnsafely(access.getEnclosingCallable(), synchronization)
}

class DefaultValue extends Literal {
    DefaultValue() {
        this.(IntegerLiteral).getIntValue() = 0
        or this.(DoubleLiteral).getValue() = "0.0"
        or this.(FloatingPointLiteral).getValue() = "0.0"
        or this.(LongLiteral).getValue() = "0"
        or this.(BooleanLiteral).getBooleanValue() = false
        or this.(CharacterLiteral).getValue().regexpMatch("\\u0000")
        or this instanceof NullLiteral
    }
}

predicate happensDuringInstanceConstruction(FieldAccess fieldAccess, RefType fieldDeclaringType) {
    exists (Callable initializingCallable |
        (
            initializingCallable instanceof InstanceInitializer
            or initializingCallable instanceof Constructor
        )
        and initializingCallable.getDeclaringType().getASourceSupertype*() = fieldDeclaringType
    |
        fieldAccess.getEnclosingCallable() = initializingCallable
    )
}

predicate requiresSafePublication(Class c) {
    exists (Field f | f = c.getAField() |
        not f.isStatic()
        and not (f.isFinal() or f.isVolatile())
    )
    or exists (RefType superType | superType = c.getASourceSupertype() |
        requiresSafePublication(superType)
    )
}

from Field f, FieldAccess synchronizedAccess, Synchronization synchronization, FieldAccess unsynchronizedAccess
where
    synchronizedAccess.getField() = f
    and not f.isFinal()
    and synchronizedAccess != unsynchronizedAccess
    and exists (RefType declaringType | declaringType = f.getDeclaringType() |
        if f.isStatic() then (
            // Ignore if access happens in static initializer of declaring type
            // because JLS guarantees that any changes in it will be visible afterwards
            not exists (StaticInitializer staticInit | staticInit.getDeclaringType() = declaringType |
                synchronizedAccess.getEnclosingCallable() = staticInit
                or unsynchronizedAccess.getEnclosingCallable() = staticInit
            )
            // Ignore if both accesses happen in same static initializer
            // Static initializers are only executed once so there cannot be a race condition
            and not exists (StaticInitializer staticInit |
                synchronizedAccess.getEnclosingCallable() = staticInit
                and unsynchronizedAccess.getEnclosingCallable() = staticInit
            )
        ) else (
            // Ignore if unsynchronizedAccess happens during construction of instance
            // This would only be a problem if object is not safely published to other thread
            // which is rather unlikely and might be detected by this query as well
            not happensDuringInstanceConstruction(unsynchronizedAccess, declaringType)
        )
    )
    // Check that synchronization directly includes access (and not only isAccessGuardedBy)
    // to make sure that the field is really intended for concurrent use
    and synchronization.includes(synchronizedAccess)
    and not isAccessGuardedBy(unsynchronizedAccess, synchronization)
    and accessSameField(synchronizedAccess, unsynchronizedAccess)
    and if not f.isVolatile() then (
        // For non-volatile fields any write makes it unsafe
        (synchronizedAccess.isLValue() or unsynchronizedAccess.isLValue())
        // Ignore if unsynchronized access is default value check
        and (
            // double and long are 64-bit large and Java Memory Model does not guarantee
            // that writes to them are atomic so non-volatile access is not safe
            f.getType().hasName(["double", "long"])
            // Class instances requiring safe publication must not be stored in non-volatile field
            or requiresSafePublication(f.getType())
            or not exists (EqualityTest defaultValueCheck, DefaultValue defaultValue |
                unsynchronizedAccess.isRValue()
                and DataFlow::localFlow(DataFlow::exprNode(unsynchronizedAccess), DataFlow::exprNode(defaultValueCheck.getAnOperand()))
                and defaultValueCheck.getAnOperand() = defaultValue
            )
        )
    ) else (
        // For volatile fields have to consider non-repeatable reads and lost updates
        
        // Unsynchronized access writes to field and synchronized access accesses
        // field twice (potential non-repeatable read / lost update)
        (
            unsynchronizedAccess.isLValue()
            and (
                synchronizedAccess.isLValue() and synchronizedAccess.isRValue() // e.g. compound assignment
                or exists (FieldAccess otherSnycAccess | accessSameField(synchronizedAccess, otherSnycAccess) |
                    otherSnycAccess != synchronizedAccess
                    and synchronization.includes(otherSnycAccess)
                )
            )
        )
        // Or field is accessed in an unsynchronized way twice and:
        //     - One access is write (potential lost update)
        //     - OR synchronized access is write (potential non-repeatable read / lost update in unsynchronized)
        or (
            unsynchronizedAccess.isLValue() and unsynchronizedAccess.isRValue() // e.g. compound assignment
            and synchronizedAccess.isLValue()
        )
        or exists (FieldAccess otherUnsyncAccess | accessSameField(unsynchronizedAccess, otherUnsyncAccess) |
            otherUnsyncAccess != unsynchronizedAccess
            and otherUnsyncAccess.getEnclosingCallable() = unsynchronizedAccess.getEnclosingCallable()
            and not isAccessGuardedBy(otherUnsyncAccess, synchronization)
            and (
                unsynchronizedAccess.isLValue() or otherUnsyncAccess.isLValue()
                or (
                    synchronizedAccess.isLValue()
                    and (unsynchronizedAccess.isRValue() or otherUnsyncAccess.isRValue())
                )
            )
        )
    )
    // Make sure there is no other synchronization which guards boths accesses
    // Could be the case when synchronization on different objects is nested
    and not exists (Synchronization otherSynchronization | otherSynchronization != synchronization |
        isAccessGuardedBy(synchronizedAccess, otherSynchronization)
        and isAccessGuardedBy(unsynchronizedAccess, otherSynchronization)
    )
select unsynchronizedAccess, "Unsynchronized access despite $@ guarding access $@.", synchronization, synchronization.describe(), synchronizedAccess, "here"