/**
 * Finds `public` or `protected` nested types within non-`public` or `protected`
 * enclosing types. While a type in a different package cannot access the public
 * members of that nested type directly from source, it can use reflection to do so,
 * because the only requirement is that the accessed type itself is public or
 * protected, regardless of the visibility of any enclosing type.
 *
 * To properly protect implementation details, the nested type should not be
 * public or protected if its enclosing types are not public or protected
 * either.
 *
 * See
 * https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/lang/reflect/AccessibleObject.html#setAccessible(boolean)
 * https://docs.oracle.com/javase/specs/jls/se11/html/jls-15.html#jls-15.12.4.3
 */

import java

from NestedType nestedType, RefType enclosing
where
    enclosing = nestedType.getEnclosingType+()
    and (
        (
            nestedType.isPublic()
            and not enclosing.isPublic()
        )
        or (
            nestedType.isProtected()
            and not enclosing.isPublic()
            and not enclosing.isProtected()
        )
    )
select nestedType, enclosing
