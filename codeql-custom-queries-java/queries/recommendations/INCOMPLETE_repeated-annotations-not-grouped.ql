/**
 * Finds repeated annotations which are not grouped but where an annotation of a
 * different type appears between them instead. E.g.:
 * ```java
 * @Marker("a")
 * @Other
 * @Marker("b")
 * String s;
 * ```
 * 
 * To increase readability it might be better to group annotations of the same type.
 */

import java
import lib.Annotations

from Annotatable annotated, AnnotationType annType, Annotation containerAnn, Annotation a1, Annotation a2, Annotation other
where
    annotated.fromSource()
    and getADeclaredAnnotation(annotated) = containerAnn
    and a1.getType() = annType
    and a2.getType() = annType
    // Verify that annotations are Repeatable (ignore containers for non-Repeatable)
    and annType.getAnAnnotation().(RepeatableAnnotation).getContainingType() = containerAnn.getType()
    // Container is created implicitly, does not exist in source
    and not containerAnn.getCompilationUnit().fromSource()
    and a1 = containerAnn.getAValue("value")
    and a2 = containerAnn.getAValue("value")
    and getADeclaredAnnotation(annotated) = other
    and annType != other.getType()
    // Make sure not to match the implicit container as "other"
    and containerAnn != other
    and a1 != a2
    and a1.getIndex() < a2.getIndex()
    // TODO Currently not possible due to https://github.com/github/codeql/issues/6236
    // ... check location of annotations, intra-line (column locations) or different lines; a1.end < other.start && other.end < a2.start
select other, "Annotation is between $@ and $@ annotation of the same type", a1, "this", a2, "this"
