/**
 * Finds `catch` clauses catching exceptions which are normally avoidable
 * by validating arguments or fields before using them, e.g. by checking
 * that they are not null.
 *
 * Catching an exception to handle this situation can hide other issues
 * which are throwing the same exception type.
 */

import java

class PreventableExceptionType extends Class {
    PreventableExceptionType() {
        this.hasQualifiedName("java.lang", "NullPointerException")
        or this instanceof TypeClassCastException
        or this.hasQualifiedName("java.lang", "NegativeArraySizeException")
        or this.hasQualifiedName("java.lang", "IndexOutOfBoundsException")
        or this.hasQualifiedName("java.lang", "ArrayStoreException")
        or this.hasQualifiedName("java.nio", "BufferUnderflowException")
        or this.hasQualifiedName("java.nio", "BufferOverflowException")
        or this.hasQualifiedName("java.util", "ConcurrentModificationException")
        or this.hasQualifiedName("java.util", "EmptyStackException")
    }
}

predicate isWithinTestClass(RefType type) {
    type instanceof TestClass
    or isWithinTestClass(type.getEnclosingType())
}

from CatchClause catch, RefType caught
where
    caught = catch.getACaughtType()
    // Ignore test classes
    and not isWithinTestClass(catch.getEnclosingCallable().getDeclaringType())
    and caught.getAnAncestor() instanceof PreventableExceptionType
select catch, caught
