/**
 * Finds fields declared by `Serializable` classes which seem to represent native
 * pointers but are not excluded for deserialization.
 * 
 * The class declaring the field might write to the memory location specified by
 * the field value or try to free memory at that location. Therefore if the field
 * value can be controlled by an adversary through deserialization, then it might
 * be possible for them to trigger a memory corruption or potentially even a
 * remote code execution.
 * 
 * See also blog post [Exploiting memory corruption vulnerabilities on Android](https://blog.oversecured.com/Exploiting-memory-corruption-vulnerabilities-on-Android/#using-attacker-controlled-native-pointers).
 */

import java

class NativePointerMethod extends Method {
    NativePointerMethod() {
        isNative()
        // Ignore methods whose `long` value does not represent a pointer
        and not(
            getDeclaringType() instanceof TypeSystem
            and hasName(["currentTimeMillis", "nanoTime"])
        )
        and not(
            getDeclaringType().hasQualifiedName("java.lang", "Thread")
            and hasName("sleep")
        )
    }
}

// TODO: Could possibly reduce false positives by checking for `readObject` or `readResolve` method

Field getADeserializedNativePointerField(Class owner) {
    result.getDeclaringType() = owner.getASourceSupertype*()
    // Make sure field is actually deserialized
    and result.getDeclaringType().getASourceSupertype*() instanceof TypeSerializable
    and not result.isStatic()
    and not result.isTransient()
    // Make sure field represents a native pointer
    and exists(MethodAccess nativeMethodCall, NativePointerMethod nativeMethod |
        nativeMethod = nativeMethodCall.getMethod()
    |
        exists(int index, Parameter p | p = nativeMethod.getParameter(index) |
            // Pointer passed as argument
            nativeMethodCall.getArgument(index) = result.getAnAccess()
            // Assume that pointer uses `long` as type
            and p.getType().(PrimitiveType).hasName("long")
        )
        or (
            // Or pointer received as result
            result.getAnAssignedValue() = nativeMethodCall
            // Assume that pointer uses `long` as type
            and nativeMethod.getReturnType().(PrimitiveType).hasName("long")
        )
    )
    // Assume that pointer uses `long` as type
    and result.getType().(PrimitiveType).hasName("long")
}

from Class owner, Field nativePointerField
where
    owner.fromSource()
    and owner.getASourceSupertype*() instanceof TypeSerializable
    and nativePointerField = getADeserializedNativePointerField(owner)
select nativePointerField, "Field seems to represent native pointer, but can be deserialized"
