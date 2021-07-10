import java

// Hacky workaround to prevent Class from choosing inherited annotations
private class DeclaredAnnotationsRetriever extends Class, RefType {
    override
    Annotation getAnAnnotation() {
        result = RefType.super.getAnAnnotation()
    }
}

/**
 * Gets a declared annotation of the annotated element. Unlike `Annotatable.getAnAnnotation()`
 * this predicate does not have inherited annotations as result.
 */
Annotation getADeclaredAnnotation(Annotatable annotated) {
    if (annotated instanceof Class) then result = annotated.(DeclaredAnnotationsRetriever).getAnAnnotation()
    else result = annotated.getAnAnnotation()
}

bindingset[targetType]
predicate isApplicableToTargetType(AnnotationType annotationType, string targetType) {
    if (annotationType.getAnAnnotation() instanceof TargetAnnotation) then (
        targetType = annotationType.getAnAnnotation().(TargetAnnotation).getATargetElementType()
    ) else (
        // No Target annotation means "applicable to all contexts" since JDK 14, see https://bugs.openjdk.java.net/browse/JDK-8231435
        // The compiler does not completely implement that, but pretend it did
        any()
    )
}

/**
 * Gets a string which describes the target types of the annotation type in a
 * human-readable format.
 */
string describeTargetTypes(AnnotationType annotationType) {
    if (annotationType.getAnAnnotation() instanceof TargetAnnotation) then (
        result = concat(annotationType.getAnAnnotation().(TargetAnnotation).getATargetElementType(), ", ")
    ) else (
        // No Target annotation means "applicable to all contexts" since JDK 14, see https://bugs.openjdk.java.net/browse/JDK-8231435
        // The compiler does not completely implement that, but pretend it did
        result = "<all>"
    )
}

class RepeatableAnnotation extends Annotation {
    RepeatableAnnotation() {
        getType().hasQualifiedName("java.lang.annotation", "Repeatable")
    }

    /**
     * Gets the annotation type which acts as _containing type_, grouping multiple
     * repeatable annotations together.
     */
    AnnotationType getContainingType() {
        // Get annotation type A of Class<A> specified by `value`
        result = getValue("value").(TypeLiteral).getTypeName().getType()
    }
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
