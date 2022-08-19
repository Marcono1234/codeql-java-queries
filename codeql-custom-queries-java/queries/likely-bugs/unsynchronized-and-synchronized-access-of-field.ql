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
 * 
 * @kind problem
 */

// TODO: Improve performance; currently it is pretty bad

import java
import semmle.code.java.dataflow.DataFlow

import lib.ConcurrencyLib
import lib.Literals

predicate accessSameField(FieldAccess a, FieldAccess b) {
    exists(Field f |
        a.getField() = f
        and b.getField() = f
    |
        f.isStatic()
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
            and other.usesSameLockAs(synchronization)
        )
        and canBeCalledUnsafely(call.getCaller(), synchronization)
    )
}

predicate isAccessGuardedBy(FieldAccess access, Synchronization synchronization) {
    isExprSynchronizedBy(access, synchronization)
    or not canBeCalledUnsafely(access.getEnclosingCallable(), synchronization)
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

predicate isSafeAccessDuringInitialization(Field f, FieldAccess synchronizedAccess, FieldAccess unsynchronizedAccess) {
    exists (RefType declaringType | declaringType = f.getDeclaringType() |
        if f.isStatic() then (
            // Ignore if access happens in static initializer of declaring type
            // because JLS guarantees that any changes in it will be visible afterwards
            exists (StaticInitializer staticInit | staticInit.getDeclaringType() = declaringType |
                synchronizedAccess.getEnclosingCallable() = staticInit
                or unsynchronizedAccess.getEnclosingCallable() = staticInit
            )
            // Ignore if both accesses happen in same static initializer
            // Static initializers are only executed once so there cannot be a race condition
            or exists (StaticInitializer staticInit |
                synchronizedAccess.getEnclosingCallable() = staticInit
                and unsynchronizedAccess.getEnclosingCallable() = staticInit
            )
        ) else (
            // Ignore if unsynchronizedAccess happens during construction of instance
            // This would only be a problem if object is not safely published to other thread
            // which is rather unlikely and might be detected by this query as well
            happensDuringInstanceConstruction(unsynchronizedAccess, declaringType)
        )
    )
}

predicate isVolatileAccessUnsafe(FieldAccess synchronizedAccess, FieldAccess unsynchronizedAccess, Synchronization synchronization) {
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
}

predicate isNonVolatileAccessUnsafe(Field f, FieldAccess synchronizedAccess, FieldAccess unsynchronizedAccess) {
    // For non-volatile fields any write makes it unsafe
    (synchronizedAccess.isLValue() or unsynchronizedAccess.isLValue())
    // Ignore if unsynchronized access is default value check
    and (
        // double and long are 64-bit large and Java Memory Model does not guarantee
        // that writes to them are atomic so non-volatile access is not safe
        f.getType().hasName(["double", "long"])
        // Class instances requiring safe publication must not be stored in non-volatile field
        or requiresSafePublication(f.getType())
        or not exists (EqualityTest defaultValueCheck, DefaultValueLiteral defaultValue |
            unsynchronizedAccess.isRValue()
            and DataFlow::localExprFlow(unsynchronizedAccess, defaultValueCheck.getAnOperand())
            and defaultValueCheck.getAnOperand() = defaultValue
        )
    )
}

from Field f, FieldAccess synchronizedAccess, Synchronization synchronization, FieldAccess unsynchronizedAccess
where
    synchronizedAccess.getField() = f
    and accessSameField(synchronizedAccess, unsynchronizedAccess)
    and not f.isFinal()
    and synchronizedAccess != unsynchronizedAccess
    and not isSafeAccessDuringInitialization(f, synchronizedAccess, unsynchronizedAccess)
    // Check that synchronization directly includes access (and not only isAccessGuardedBy)
    // to make sure that the field is really intended for concurrent use
    and synchronization.includes(synchronizedAccess)
    and not isAccessGuardedBy(unsynchronizedAccess, synchronization)
    and if f.isVolatile() then (
        isVolatileAccessUnsafe(synchronizedAccess, unsynchronizedAccess, synchronization)
    ) else (
        isNonVolatileAccessUnsafe(f, synchronizedAccess, unsynchronizedAccess)
    )
    // Make sure there is no other synchronization which guards boths accesses
    // Could be the case when synchronization on different objects is nested
    and not exists (Synchronization otherSynchronization | otherSynchronization != synchronization |
        isAccessGuardedBy(synchronizedAccess, otherSynchronization)
        and isAccessGuardedBy(unsynchronizedAccess, otherSynchronization)
    )
select unsynchronizedAccess, "Unsynchronized access despite $@ guarding access $@.", synchronization, synchronization.describe(), synchronizedAccess, "here"
