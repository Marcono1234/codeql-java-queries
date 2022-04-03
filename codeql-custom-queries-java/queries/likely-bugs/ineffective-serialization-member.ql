/**
 * Finds members which have the same name or signature as Java serialization members, e.g. a
 * field named `serialVersionUID`, but which have in this context no effect, for example
 * because the declaring class does not implement `java.io.Serializable`.
 */

import java

import lib.JavaSerialization

from RefType t, boolean isExternalizable, boolean isSerializableRecord, Member m, string typeDescription
where
    t.fromSource()
    and m.getDeclaringType() = t
    and (
        // Cover these with if-else to ignore in case they implement Externalizable
        if t instanceof Interface then isExternalizable = false and isSerializableRecord = false and typeDescription = "interface"
        // https://docs.oracle.com/en/java/javase/17/docs/specs/serialization/serial-arch.html#serialization-of-enum-constants
        else if t instanceof EnumType then isExternalizable = false and isSerializableRecord = false and typeDescription = "enum"
        // https://docs.oracle.com/en/java/javase/17/docs/specs/serialization/serial-arch.html#serialization-of-records
        else if t instanceof Record and t.getASourceSupertype+() instanceof TypeSerializable then isExternalizable = false and isSerializableRecord = true and typeDescription = "record class"
        else isSerializableRecord = false and (
            isExternalizable = true and t.getSourceDeclaration().getASourceSupertype*() instanceof TypeExternalizable
            and typeDescription = "Externalizable type"
            or
            isExternalizable = false and not t.getSourceDeclaration().getASourceSupertype*() instanceof TypeSerializable
            and typeDescription = "non-Serializable type"
        )
    )
    and (
        m.(Field).hasName("serialPersistentFields")
        // serialVersionUID works for Externalizable and record
        or isExternalizable = false and isSerializableRecord = false and m.(Field).hasName("serialVersionUID")
        or m.(Method).hasStringSignature([
            "writeObject(ObjectOutputStream)",
            "readObject(ObjectInputStream)",
            "readObjectNoData()"
        ])
        or
        // writeReplace and readResolve work for Externalizable and record
        isExternalizable = false and isSerializableRecord = false and m.(Method).hasStringSignature([
            "writeReplace()",
            "readResolve()"
        ])
        // And ignore if Serializable subtype exists which inherits these methods
        and not exists(RefType subtype, Method method |
            subtype.getASourceSupertype+() = t
            and subtype.getASourceSupertype+() instanceof TypeSerializable
            and (method = m or method.getSourceDeclaration().getASourceOverriddenMethod*() = m)
            and subtype.inherits(method)
        )
    )
select m, "Ineffective serialization member in " + typeDescription
