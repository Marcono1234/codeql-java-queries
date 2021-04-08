/**
 * Finds implementations of `equals(Object)` and `hashCode()` which call `toString()`.
 * `toString()` is usually only intended to return a String representation for
 * development or logging purposes. Its return value might be ambiguous or subclasses
 * might override it in an unpredictable way.
 * In general it is better (and probably more efficient) to directly compare fields
 * or results of getter methods instead of using `toString()` when checking for
 * equality.
 */

import java

class ToStringMethod extends Method {
    ToStringMethod() {
        this.hasName("toString") and
        this.hasNoParameters()
    }
}

from Method m, MethodAccess toStringCall
where
    (m instanceof EqualsMethod or m instanceof HashCodeMethod)
    and toStringCall.getMethod() instanceof ToStringMethod
    // Only consider own `toString()` calls
    and toStringCall.isOwnMethodAccess()
    and toStringCall.getEnclosingCallable() = m
select m, "Uses toString() $@ to determine equality", toStringCall, "here"
