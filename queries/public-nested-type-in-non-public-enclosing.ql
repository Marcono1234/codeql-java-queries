/**
 * Finds `public` nested types within non-`public` enclosing types.
 * While a type in a different package cannot access that nested type
 * directly, it can use reflection to do so, because the only requirement
 * is that the type itself is public, regardless of the visibility of any
 * enclosing type.
 * See https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/lang/reflect/AccessibleObject.html#setAccessible(boolean)
 *
 * To properly protect implementation details, the nested type should
 * not be public if its enclosing types are not public either.
 */

import java

from NestedType nestedType, RefType nonPublicEnclosing
where
    nestedType.isPublic()
    and nonPublicEnclosing = nestedType.getEnclosingType+()
    and not nonPublicEnclosing.isPublic()
select nestedType, nonPublicEnclosing
