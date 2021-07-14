/**
 * Finds annotation types which specify an empty array as `@Target`, and which
 * are not referenced by another annotation type.
 * 
 * An annotation type with an empty `@Target` cannot be applied to any element,
 * it can only be used as nested annotation of another annotation type. However,
 * if no such other annotation type referencing it exists, this annotation type
 * is effectively not usable.
 */

import java

from AnnotationType annType
where
    // Explicit empty array as target types
    annType.getAnAnnotation().(TargetAnnotation).getValue("value").(ArrayInit).getSize() = 0
    // And no other annotation element use it as type
    and not exists(AnnotationElement annElement |
        annElement.getType() = annType
        or annElement.getType().(Array).getComponentType() = annType
    )
select annType, "Annotation type is not usable"
