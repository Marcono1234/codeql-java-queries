/**
 * Finds fields of classes implementing `Serializable`, whose type is not serializable
 * and for which there also exist no subtypes of that type which are serializable.
 * This most likely prevents serialization of the class declaring the field.
 * 
 * This query is similar to CodeQL's query `java/non-serializable-field`, but is more
 * precise and should only report cases where a field is definitely not serializable.
 */

import java
import lib.JavaSerialization
import lib.Types

predicate isExplicitlySerializable(Class c) {
    (
        // Directly implements Serializable
        c.getASupertype() instanceof TypeSerializable
        // Or specifies UID
        or any(SerialVersionUidField f).getDeclaringType() = c
    )
    // Ignore Externalizable because it performs custom serialization
    and not c.getASourceSupertype+() instanceof TypeExternalizable
}

// Note: Cannot use RefType.getASubtype() because it apparently does not work when supertype
// is parameterized, e.g. IntList extends List<Integer>
RefType getASubtypeOrSelf(RefType t) {
    result.getASourceSupertype*() = t
}

predicate canSelfOrSubtypeBeSerialized(RefType t) {
    t.getSourceDeclaration().getASourceSupertype*() instanceof TypeSerializable
    or canSelfOrSubtypeBeSerialized(getASubtypeOrSelf(t))
    // Or can be subclassed externally
    or isPubliclySubclassable(t)
}

RefType getUltimateBound(RefType t) {
    if t instanceof TypeVariable
    then result = getUltimateBound(t.(TypeVariable).getUpperBoundType())
    else result = t
}

from Class c, SerializedField f, RefType fieldType
where
    f.fromSource()
    and f.getDeclaringType() = c
    // Only consider if explicitly serializable; ignore if it is inherited but serialization
    // might not actually be desired
    and isExplicitlySerializable(c)
    // Ignore if performing custom serialization
    and not any(WriteObjectSerializableMethod m).getDeclaringType() = c
    and not any(WriteReplaceSerializableMethod m).getDeclaringType() = c
    and fieldType = f.getType()
    and not canSelfOrSubtypeBeSerialized(getUltimateBound(fieldType).getSourceDeclaration())
select f, "Field value cannot be serialized, because its type is not serializable and has no serializable subtypes"
