import java

/**
 * Annotation indicating whether the annotated element can be `null` or not.
 */
abstract class NullnessAnnotation extends Annotation {
}

/**
 * Annotation indicating that the annotated element is not `null`.
 */
class NonNullAnnotation extends NullnessAnnotation {
    NonNullAnnotation() {
        getType().getName().toLowerCase() = [
            "notnull",
            "nonnull"
        ]
    }
}

/**
 * Annotation indicating that the annotated element may be `null`.
 */
class NullableAnnotation extends NullnessAnnotation {
    NullableAnnotation() {
        getType().hasName([
            "Nullable"
        ])
    }
}

/**
 * Method which checks for nullness of one its arguments.
 */
abstract class NullnessCheckingMethod extends Method {
    /**
     * Gets the index of the parameter which is checked for nullness.
     */
    abstract int getNullCheckedParamIndex();
}

private class TypeObjects extends Class {
    TypeObjects() {
        hasQualifiedName("java.util", "Objects")
    }
}

private class ObjectsRequireNonNullMethod extends NullnessCheckingMethod {
    ObjectsRequireNonNullMethod() {
        getDeclaringType() instanceof TypeObjects
        and hasName([
            "requireNonNull",
            "requireNonNullElse",
            "requireNonNullElseGet"
        ])
    }

    override
    int getNullCheckedParamIndex() { result = 0 }
}

private class ObjectsNullPredicateMethod extends NullnessCheckingMethod {
    ObjectsNullPredicateMethod() {
        getDeclaringType() instanceof TypeObjects
        and hasName([
            "isNull",
            "nonNull"
        ])
    }

    override
    int getNullCheckedParamIndex() { result = 0 }
}
