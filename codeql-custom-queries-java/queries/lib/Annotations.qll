import java

/**
 * Gets a string which describes the target types of the annotation type in a
 * human-readable format.
 */
string describeTargetTypes(AnnotationType annotationType) {
    if (annotationType.getAnAnnotation() instanceof TargetAnnotation) then (
        result = concat(annotationType.getAnAnnotation().(TargetAnnotation).getATargetElementType(), ", ")
    ) else (
        // No Target annotation means "applicable in all contexts" since JDK 14, see https://bugs.openjdk.java.net/browse/JDK-8231435
        // Respectively "applicable in all declaration contexts" since JDK 17, see https://bugs.openjdk.java.net/browse/JDK-8261610
        // The compiler does not completely implement that, but pretend it did
        result = "<all>"
    )
}

class DocumentedAnnotation extends Annotation {
    DocumentedAnnotation() {
        getType().hasQualifiedName("java.lang.annotation", "Documented")
    }
}

class InheritedAnnotation extends Annotation {
    InheritedAnnotation() {
        getType().hasQualifiedName("java.lang.annotation", "Inherited")
    }
}
