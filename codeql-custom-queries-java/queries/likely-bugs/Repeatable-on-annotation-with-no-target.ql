/**
 * Finds annotation types which specify an empty array as `@Target`, but which
 * are also meta-annotated with `@Repeatable`.
 * 
 * An annotation type with an empty `@Target` cannot be applied to any element,
 * therefore it does not make sense to annotate it with `@Repeatable` since
 * that is only useful when an annotation is applied to an element. 
 */

import java
import lib.Annotations

from AnnotationType annType, RepeatableAnnotation repeatableAnn
where
    // Explicit empty array as target types
    annType.getAnAnnotation().(TargetAnnotation).getValue("value").(ArrayInit).getSize() = 0
    and repeatableAnn = annType.getAnAnnotation()
select repeatableAnn, "@Repeatable meta-annotation is pointless"
