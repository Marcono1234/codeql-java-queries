/**
 * Finds `assert` statements which appear to perform argument validation.
 * It is not recommended to do this since it has the following disadvantages:
 *   - Assertions might be disabled at runtime and therefore invalid arguments
 *     might not be detected
 *   - The `assert` statement throws an `AssertionError` (extends `Error`) which
 *     is likely not explicitly caught and should not be caught and therefore
 *     might cause the complete application to terminate
 *
 * Instead use methods or frameworks explicitly designed for argument validation,
 * e.g. `java.util.Objects` methods or Guava's `Preconditions` methods.
 *
 * See also https://docs.oracle.com/javase/specs/jls/se14/html/jls-14.html#jls-14.10
 */

import java
import lib.Types

predicate canTypeBeSeen(RefType refType) {
    if refType.isTopLevel() then (
        refType.isPublic()
    ) else (
        (
            refType.isPublic()
            or refType.isProtected()
        )
        and canTypeBeSeen(refType.getEnclosingType())
    )
}

from AssertStmt assertStmt, Callable callable, RValue paramRead
where
    assertStmt.getEnclosingCallable() = callable
    and paramRead.getVariable() = callable.getAParameter()
    and paramRead.getEnclosingStmt() = assertStmt
    and (
        callable.isPublic()
        or (
            callable.isProtected()
            // Ignore if class cannot be subclassed publicly because then protected
            // method cannot be called from outside either
            and not isPubliclySubclassable(callable.getDeclaringType())
        )
    )
    // TODO: Should consider whether callable can be seen for subtypes of declaring type?
    and canTypeBeSeen(callable.getDeclaringType())
select assertStmt, "Validates parameter value $@", paramRead, "here"
