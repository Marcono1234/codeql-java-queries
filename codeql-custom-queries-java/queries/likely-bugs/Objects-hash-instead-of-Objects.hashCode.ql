/**
 * As described by the `java.util.Objects.hash(Object...)` doc, this method
 * behaves differently than calling `obj.hashCode()` for a single object.
 * Therefore if the hash code of a single object should be calculated,
 * it might be better to call `Objects.hash(Object)` instead.
 */

import java

from MethodAccess call, Method method
where
    call.getMethod() = method
    and method.hasStringSignature("hash(Object[])") // Signature is actually "hash(Object...)"
    and method.getDeclaringType().hasQualifiedName("java.util", "Objects")
    // If called with >= 2 arguments, hash(Object...) is appropriate
    and call.getNumArgument() < 2
select call
