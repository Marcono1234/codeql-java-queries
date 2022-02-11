/**
 * Finds classes implementing `Serializable`, which define either `readObject`
 * or `writeObject` but not the corresponding other method. This might indicate that
 * the other method was omitted by accident, and that the class is not actually
 * properly serializable.
 */

// TODO: Not properly tested yet

import java
import lib.JavaSerialization

predicate isMissingMethod(Method serializationMethod, Method other) {
    serializationMethod instanceof ReadObjectSerializableMethod
    and other instanceof WriteObjectSerializableMethod
    or
    serializationMethod instanceof WriteObjectSerializableMethod
    and other instanceof ReadObjectSerializableMethod
}

from Class c, Method existingMethod, string missingMethodName
where
    c.getASourceSupertype+() instanceof TypeSerializable
    and (
        existingMethod.(ReadObjectSerializableMethod).getDeclaringType() = c
        and missingMethodName = "writeObject"
        // And readObject performs custom read and does not merely perform validation or
        // reconstruction of transitive field values
        and exists(MethodAccess customReadCall |
            customReadCall.getQualifier() = existingMethod.getParameter(0).getAnAccess()
            and not customReadCall.getMethod().hasStringSignature([
                "defaultReadObject()",
                "readFields()",
            ])
        )
        or
        existingMethod.(WriteObjectSerializableMethod).getDeclaringType() = c
        and missingMethodName = "readObject"
        // And writeObject performs custom write and does not merely synchronize on lock
        // or set up instance for serialization
        and exists(MethodAccess customReadCall |
            customReadCall.getQualifier() = existingMethod.getParameter(0).getAnAccess()
            and not customReadCall.getMethod().hasStringSignature([
                "defaultWriteObject()",
                "putFields()",
            ])
        )
    )
    and not exists(Class subOrSupertype |
        // Also consider self
        subOrSupertype = c.getASourceSupertype*()
        or subOrSupertype.getASourceSupertype*() = c
    |
        // Implements the missing method
        isMissingMethod(existingMethod, subOrSupertype.getAMethod())
        or
        // Or only deserialized as replacement
        existingMethod instanceof ReadObjectSerializableMethod
        and subOrSupertype.getAMethod() instanceof ReadResolveSerializableMethod
    )
select c, "Implements $@, but does not implement " + missingMethodName, existingMethod, existingMethod.getName()
