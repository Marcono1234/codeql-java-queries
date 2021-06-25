/**
 * Finds code which uses Java deserialization to deserialize an instance of a functional
 * interface. Functional interfaces are used in many contexts, it could therefore be the
 * case that in a completely unrelated part of the application a serializable functional
 * expression performs a dangerous operation, such as starting a process or allocating
 * memory of arbitrary size. This could be exploited by an adversary who stores a
 * reference to this dangerous functional expression in the serialized data.
 * 
 * For example consider the two library classes:
 * ```java
 * interface SerializableSupplier<T> extends Supplier<T>, Serializable {
 * }
 *
 * // Serializable class with field of functional interface type Supplier
 * class Lazy<T> implements Serializable {
 *     private final Supplier<T> supplier;
 *     private T value;
 * 
 *     public Lazy(Supplier<T> supplier) {
 *         this.supplier = supplier;
 *     }
 * 
 *     public T getValue() {
 *         if (value == null) {
 *             value = supplier.get();
 *         }
 *         return value;
 *     }
 * }
 * ```
 * Let's imagine `SerializaleSupplier` is now used in a completely unrelated part of
 * the application for a dangerous action, e.g.:
 * ```java
 * public static void main(String... args) throws Exception {
 *     // Uses a functional expression for starting a command using a captured argument
 *     doSomething(() -> {
 *         try {
 *             return Runtime.getRuntime().exec(args[0]);
 *         } catch (IOException e) {
 *             throw new UncheckedIOException(e);
 *         }
 *     });
 * 
 *     ...
 * }
 * 
 * private static void doSomething(SerializableSupplier<?> supplier) {
 *     ...
 * }
 * ```
 * Then an adversary can provide malicious serialized data for `Lazy` where the `supplier`
 * is a serialized lambda performing the action of the functional expression above (i.e.
 * starting a process) with an arbitrary process name (since it is part of the captured
 * lambda arguments).
 */

import java
import semmle.code.java.dataflow.DataFlow

class FunctionalInterfaceAnnotation extends Annotation {
    FunctionalInterfaceAnnotation() {
        getType().hasQualifiedName("java.lang", "FunctionalInterface")
    }
}

// Only consider interfaces; classes implementing functional interfaces cannot be used as functional
// expression
class FunctionalInterfaceType extends Interface {
    FunctionalInterfaceType() {
        // Only consider if explicitly marked as functional interface to cover only general
        // purpose functional interfaces
        getASourceSupertype*().getAnAnnotation() instanceof FunctionalInterfaceAnnotation
    }
}

// Note: Could cause false positives when class declaring or inheriting field has
// readObject(ObjectInputStream) method which prevents deserialization or does not read fields
Field getDeserializedFunctionalInterfaceField() {
    result.fromSource()
    and result.getType() instanceof FunctionalInterfaceType
    // Check for serializable type which is the same or parent of declaring
    // type of field (otherwise field is not deserialized)
    and exists(RefType serializableDeclaringType |
        serializableDeclaringType.getASourceSupertype() instanceof TypeSerializable
        and result.getDeclaringType().getASourceSupertype*() = serializableDeclaringType
    )
    // Ignore if field is not deserialized
    and not result.isTransient()
    and not result.isStatic()
    // Ignore fields declared by enums since enum constants are deserialized by name
    and not result.getDeclaringType() instanceof EnumType
}

class ObjectReadingMethod extends Method {
    ObjectReadingMethod() {
        getASourceOverriddenMethod*() instanceof ReadObjectMethod
        // ObjectInput.readObject() is not covered by ReadObjectMethod
        or (
            getDeclaringType().getASourceSupertype*().hasQualifiedName("java.io", "ObjectInput")
            and hasStringSignature("readObject()")
        )
    }
}

MethodAccess getFunctionalInterfaceReadingCall() {
    result.getMethod() instanceof ObjectReadingMethod
    and exists(Expr sink |
        sink.getType() instanceof FunctionalInterfaceType
        // Read object flows to sink of functional interface type, i.e.
        // a cast expression
        and DataFlow::localExprFlow(result, sink)
    )
}

from Top deserializingFunctionalInterface, string message
where
    (
        deserializingFunctionalInterface = getDeserializedFunctionalInterfaceField()
        and message = "Field with functional interface type is deserialized"
    )
    or (
        deserializingFunctionalInterface = getFunctionalInterfaceReadingCall()
        and message = "Deserializes functional interface instance"
    )
select deserializingFunctionalInterface, message
