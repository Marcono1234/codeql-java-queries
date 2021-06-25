/**
 * Finds interfaces annotated with `@FunctionalInterface` which
 * implement `Serializable`.
 * 
 * Functional interface serialization support is in part provided by
 * the compiler so switching or upgrading the compiler could prevent
 * existing serialized functional expressions from being deserialized.
 *
 * Additionally for any class which contains a functional expression
 * implementing that serializable interface the functional expression
 * can – even if it accesses internal fields or methods – be executed
 * by anyone who deserializes an instance of this functional expression
 * through a forged `SerializedLambda`.
 * See also https://stackoverflow.com/q/25443655/
 */

import java

class FunctionalInterfaceAnnotation extends Annotation {
    FunctionalInterfaceAnnotation() {
        getType().hasQualifiedName("java.lang", "FunctionalInterface") 
    }
}

from Interface interface
where
    interface.getAnAnnotation() instanceof FunctionalInterfaceAnnotation
    and interface.getAnAncestor() instanceof TypeSerializable
select interface
