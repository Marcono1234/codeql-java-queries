/**
 * Finds classes implementing `Serializable` whose `readObject` method calls
 * `defaultReadObject()` and then validates some field values, but which does
 * not validate the value of one of the other deserialized fields.
 * 
 * @kind problem
 * @precision low
 */

import java
import lib.JavaSerialization

from ReadObjectSerializableMethod readObjectMethod, SerializedField serializedField
where
    readObjectMethod.getDeclaringType() = serializedField.getDeclaringType()
    // And method seems to perform some validation
    and any(ThrowStmt t).getEnclosingCallable() = readObjectMethod
    // And calls `defaultReadObject()`
    and exists(MethodAccess defaultReadObjectCall |
        defaultReadObjectCall.getEnclosingCallable() = readObjectMethod
        and defaultReadObjectCall.getMethod() instanceof DefaultReadObjectMethod
    )
    // But does not check or overwrite deserialized field value
    and not exists(FieldAccess fieldAccess |
        fieldAccess.getField() = serializedField
        and fieldAccess.getEnclosingCallable() = readObjectMethod
    )
    // Ignore types which are most likely safe
    and not serializedField.getType() instanceof BooleanType
select readObjectMethod, "Does not validate value of field $@", serializedField, serializedField.getName()
