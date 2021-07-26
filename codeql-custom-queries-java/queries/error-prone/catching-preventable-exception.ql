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
        this instanceof TypeClassCastException
        or this.hasQualifiedName("java.lang", [
            "NullPointerException",
            "NegativeArraySizeException",
            "IndexOutOfBoundsException",
            "ArrayStoreException",
            // Could use Thread.holdsLock(Object)
            // Based on SpotBugs `IMSE_DONT_CATCH_IMSE`
            "IllegalMonitorStateException"
        ])
        or this.hasQualifiedName("java.nio", [
            "BufferUnderflowException",
            "BufferOverflowException"
        ])
        or this.hasQualifiedName("java.util", [
            "ConcurrentModificationException",
            "EmptyStackException"
        ])
    }
}

from CatchClause catch, RefType caught
where
    caught = catch.getACaughtType()
    // Ignore test classes
    and not catch.getEnclosingCallable().getDeclaringType() instanceof TestClass
    and caught.getAnAncestor() instanceof PreventableExceptionType
select catch, "Catches preventable exception " + caught.getName()
