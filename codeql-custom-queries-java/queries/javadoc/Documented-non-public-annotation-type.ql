/**
 * Finds usage of `@Documented` on annotation types which are not publicly visible.
 * Usually documentation is only generated for `protected` and `public` elements.
 * Therefore if the annotation type marked with `@Documented` is not publicly visible,
 * it will itself not be documented. However, any usage of the annotation type on
 * other elements will be documented. This can be confusing to users because they see
 * the annotation in the documentation, but cannot find out what the annotation means.
 */

// See also related https://bugs.openjdk.java.net/browse/JDK-8139744

import java
import lib.Annotations

// TODO: Add library predicate for this; other queries define this as well
predicate isPubliclyVisible(RefType t) {
    t.isTopLevel() and t.isPublic()
    or
    (t.isProtected() or t.isPublic()) and isPubliclyVisible(t.getEnclosingType())
}

from DocumentedAnnotation documentedAnnotation, AnnotationType annotationType
where
    annotationType.getAnAnnotation() = documentedAnnotation
    and not isPubliclyVisible(annotationType)
select documentedAnnotation, "Marks non-public annotation type as @Documented"
