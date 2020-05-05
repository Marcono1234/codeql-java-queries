/**
 * Finds interfaces annotated with `@FunctionalInterface` which
 * implement `Serializable`.
 * 
 * Functional interface serialization support is in part provided by
 * the compiler so switching or upgrading the compiler could prevent
 * existing serialized functional expressions from being deserialized.
 *
 * Additionally any class which contains a functional expression
 * implementing a serializable interface allows any of its methods
 * (including private ones) to be called by a deserialized forged
 * functional expression.
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
