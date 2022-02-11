import java

/**
 * `java.io.Externalizable`
 */
class TypeExternalizable extends Interface {
    TypeExternalizable() {
        hasQualifiedName("java.io", "Externalizable")
    }
}

/**
 * A field which is likely serialized.
 */
class SerializedField extends Field {
    SerializedField() {
        getDeclaringType().getASourceSupertype*() instanceof TypeSerializable
        and not isStatic()
        and not isTransient()
    }
}

/**
 * `serialVersionUID` field.
 */
class SerialVersionUidField extends Field {
    SerialVersionUidField() {
        hasName("serialVersionUID")
        and getType().hasName("long")
        and isStatic()
        and isFinal()
    }
}

/**
 * `serialPersistentFields` field.
 */
class SerialPersistentFieldsField extends Field {
    SerialPersistentFieldsField() {
        hasName("serialPersistentFields")
        and isPrivate()
        and isStatic()
        and isFinal()
    }
}

/**
 * `readObject(ObjectInputStream)` implemented by a serializable class.
 */
class ReadObjectSerializableMethod extends Method {
    ReadObjectSerializableMethod() {
        isPrivate()
        and hasStringSignature("readObject(ObjectInputStream)")
        and getReturnType() instanceof VoidType
        and getDeclaringType().getASourceSupertype*() instanceof TypeSerializable
        and not isStatic()
    }
}

/**
 * `readResolve()` implemented by a serializable class.
 */
class ReadResolveSerializableMethod extends Method {
    ReadResolveSerializableMethod() {
        hasStringSignature("readResolve()")
        and getReturnType() instanceof TypeObject
        and getDeclaringType().getASourceSupertype*() instanceof TypeSerializable
        and not isStatic()
    }
}

/**
 * `writeObject(ObjectOutputStream)` implemented by a serializable class.
 */
class WriteObjectSerializableMethod extends Method {
    WriteObjectSerializableMethod() {
        isPrivate()
        and hasStringSignature("writeObject(ObjectOutputStream)")
        and getReturnType() instanceof VoidType
        and getDeclaringType().getASourceSupertype*() instanceof TypeSerializable
        and not isStatic()
    }
}

/**
 * `writeReplace()` implemented by a serializable class.
 */
class WriteReplaceSerializableMethod extends Method {
    WriteReplaceSerializableMethod() {
        hasStringSignature("writeReplace()")
        and getReturnType() instanceof TypeObject
        and getDeclaringType().getASourceSupertype*() instanceof TypeSerializable
        and not isStatic()
    }
}

/**
 * `ObjectInputStream.defaultReadObject()`
 */
class DefaultReadObjectMethod extends Method {
    DefaultReadObjectMethod() {
        getDeclaringType().getASourceSupertype*() instanceof TypeObjectInputStream
        and hasStringSignature("defaultReadObject()")
    }
}

/**
 * `ObjectOutputStream.defaultWriteObject()`
 */
class DefaultWriteObjectMethod extends Method {
    DefaultWriteObjectMethod() {
        getDeclaringType().getASourceSupertype*() instanceof TypeObjectOutputStream
        and hasStringSignature("defaultWriteObject()")
    }
}

/**
 * `ObjectOutputStream.putFields()`
 */
class PutFieldsMethod extends Method {
    PutFieldsMethod() {
        getDeclaringType().getASourceSupertype*() instanceof TypeObjectOutputStream
        and hasStringSignature("putFields()")
    }
}
