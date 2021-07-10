/**
 * Finds usage of the meta-annotation `@Inherited` on an annotation type whose
 * `@Target` does not permit usage on classes. Annotation inheritance only works
 * for classes, therefore using `@Inherited` in this case does not make sense.
 * 
 * See [`@Inherited` documentation](https://docs.oracle.com/en/java/javase/16/docs/api/java.base/java/lang/annotation/Inherited.html).
 */

import java
import lib.Annotations

from AnnotationType ann, InheritedAnnotation inheritedAnn, TargetAnnotation targetAnn
where
    ann.fromSource()
    and inheritedAnn = ann.getAnAnnotation()
    and targetAnn = ann.getAnAnnotation()
    // `TYPE_USE` also permits usage on class declarations
    and not targetAnn.getATargetElementType() = ["TYPE", "TYPE_USE"]
select inheritedAnn, "Usage of @Inherited makes no sense because $@ does not permit usage on classes", targetAnn, "target annotation"
