/**
 * Finds `readObject` methods of classes implementing `Serializable` which do not read the
 * object fields from the serialization data, even though fields are being serialized.
 * This most likely prevents deserialization from working correctly.
 */

import java
import lib.JavaSerialization

from ReadObjectSerializableMethod m, Class declaringType
where
    declaringType = m.getDeclaringType()
    and (
        any(SerializedField f).getDeclaringType().getASourceSupertype*() = declaringType
        // And if a writeObject method exists it writes the fields by calling defaultWriteObject()
        and (
            not any(WriteObjectSerializableMethod writeObjectMethod).getDeclaringType() = declaringType
            or
            exists(WriteObjectSerializableMethod writeObjectMethod, MethodAccess defaultWriteObjectCall |
                writeObjectMethod.getDeclaringType() = declaringType
                and defaultWriteObjectCall.getMethod() instanceof DefaultWriteObjectMethod
                and defaultWriteObjectCall.getQualifier() = writeObjectMethod.getParameter(0).getAnAccess()
            )
        )
        or
        // Or by calling putFields()
        exists(WriteObjectSerializableMethod writeObjectMethod, MethodAccess putFieldsCall |
            writeObjectMethod.getDeclaringType() = declaringType
            and putFieldsCall.getMethod() instanceof PutFieldsMethod
            and putFieldsCall.getQualifier() = writeObjectMethod.getParameter(0).getAnAccess()
        )
        or
        // Or class defines serialized fields
        any(SerialPersistentFieldsField f).getDeclaringType() = declaringType
    )
    and not exists(MethodAccess fieldReadingCall |
        fieldReadingCall.getQualifier() = m.getParameter(0).getAnAccess()
    |
        fieldReadingCall.getMethod().hasStringSignature([
            "defaultReadObject()",
            "readFields()",
        ])
    )
    // Ignore if readObject prevents deserialization
    and not m.getBody().(SingletonBlock).getStmt() instanceof ThrowStmt
    // And does not call delegate method for deserialization
    and not exists(MethodAccess delegateCall |
        delegateCall.getAnArgument() = m.getParameter(0).getAnAccess()
    )
select m, "Does not read field values"
