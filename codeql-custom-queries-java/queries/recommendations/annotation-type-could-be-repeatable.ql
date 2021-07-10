/**
 * Finds annotation types which could be marked with `@Repeatable` because
 * there is already an existing other annotation type acting as container.
 */

import java
import lib.Annotations

from AnnotationType annType, AnnotationType containedAnnType
where
    containedAnnType.fromSource()
    // `value` element has array of annotation type
    and containedAnnType = annType.getAnnotationElement("value").getType().(Array).getComponentType()
    // To reduce irrelevant results ignore annotation types with other elements
    and not exists (AnnotationElement otherElement |
        otherElement = annType.getAnAnnotationElement()
        and otherElement.getName() != "value"
    )
    // Contained type is not already Repeatable
    and not containedAnnType.getAnAnnotation() instanceof RepeatableAnnotation
select annType, "Could be used as containing annotation type by marking $@ as @Repeatable", containedAnnType, "@" + containedAnnType.getName()
