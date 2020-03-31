/**
 * Finds enums with mutable fields whose value can possibly be influenced
 * from a public method.
 */

import java

from EnumType enum, FieldWrite fieldWrite
where
    fieldWrite.getField().getDeclaringType() = enum
    and fieldWrite.getEnclosingCallable().isPublic()
select fieldWrite
