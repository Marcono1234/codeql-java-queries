/**
 * Finds classes implementing `Cloneable` and overriding `clone()`
 * but not making it public (as suggested by the `Cloneable` documentation).
 *
 * Note however, that in general it is discouraged to implement `Cloneable`
 * or use `clone()` in the first place, see also CodeQL query
 * `java/use-of-cloneable-interface`.
 */

import java

from Class c, CloneMethod cloneMethod
where
    c.getASupertype() instanceof TypeCloneable
    and cloneMethod.getDeclaringType() = c
    and cloneMethod.isProtected()
    // Only consider if it is actually part of the checked project
    and cloneMethod.fromSource()
select cloneMethod, "Overrides clone() method but does not make it public"
