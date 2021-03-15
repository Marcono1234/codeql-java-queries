/**
 * Finds implementations of `clone()` which do not adjust the return type
 * to be the same as the declaring class. Because `clone()` requires that
 * the class of the returned object to be the same as the one of the object
 * on which the method was called, it should always be correct to adjust
 * the return type accordingly. Not doing so makes the method more
 * cumbersome to use.
 *
 * Note however, that in general it is discouraged to implement `Cloneable`
 * or use `clone()` in the first place, see also CodeQL query
 * `java/use-of-cloneable-interface`.
 */

import java

from Class c, CloneMethod cloneMethod, RefType returnType
where
    cloneMethod.getDeclaringType() = c
    and cloneMethod.fromSource()
    and returnType = cloneMethod.getReturnType()
    // Consider source supertype in case return type is parameterized type
    and not returnType.getASourceSupertype*() = c
    // Ignore if method always throws exception
    and not (
        cloneMethod.getBody().getNumStmt() = 1
        and cloneMethod.getBody().getAStmt() instanceof ThrowStmt
    )
select cloneMethod, "clone() returns " + returnType.getName() + " instead of " + c.getName()
