/**
 * Finds containing annotation types which have different settings than the repeatable
 * annotation type they contain (annotated with `Repeatable`), such as different targets
 * or retention.
 * 
 * While some cases of mismatch are permitted by the language specification, they
 * often make no sense, have no effect or result in inconsistencies.
 * 
 * See [JLS 16 §9.6.3](https://docs.oracle.com/javase/specs/jls/se16/html/jls-9.html#jls-9.6.3)
 * 
 * @kind problem
 */

import java
import lib.Annotations

string getMismatchMessage(AnnotationType containingAnnType, AnnotationType annType) {
    // Note: For all these cases only have to check whether containingAnnType specifies something
    // not present for annType; other cases would result in compilation error, see JLS 16 §9.6.3
    (
        containingAnnType.getAnAnnotation() instanceof DocumentedAnnotation
        and not annType.getAnAnnotation() instanceof DocumentedAnnotation
        // @Documented on containing annotation seems to have no effect on Javadoc
        and result = "Containing annotation is marked as Documented, but contained $@ is not"
    )
    or (
        containingAnnType.isInherited()
        and not annType.isInherited()
        // Using @Inherited on containing annotation only causes the container annotation to be
        // inherited, but methods such as Class.getAnnotationsByType do not find contained annotations
        and result = "Containing annotation is marked as Inherited, but contained $@ is not"
    )
    // Mismatch between explicit and implicit Target
    or (
        containingAnnType.getAnAnnotation() instanceof TargetAnnotation
        and not annType.getAnAnnotation() instanceof TargetAnnotation
        and result = "Containing annotation explicitly specifies Target, but contained $@ does not"
    )
    or (
        not containingAnnType.getAnAnnotation() instanceof TargetAnnotation
        and annType.getAnAnnotation() instanceof TargetAnnotation
        and result = "Containing annotation does not explicitly specify Target, but contained $@ does"
    )
    // Mismatch between Target ElementType values
    or exists(TargetAnnotation containingAnnTarget, TargetAnnotation annTarget |
        containingAnnTarget = containingAnnType.getAnAnnotation()
        and annTarget = annType.getAnAnnotation()
    |
        not forall(string target | target = annTarget.getATargetElementType() |
            target = containingAnnTarget.getATargetElementType()
        )
        // Using different @Target prevents repeating annotation on elements on which a single
        // annotation would be permitted, which is most likely not intended
        and result = "Containing annotation uses different Target than contained $@"
    )
    // Mismatch between explicit and implicit Retention
    or (
        containingAnnType.getAnAnnotation() instanceof RetentionAnnotation
        and not annType.getAnAnnotation() instanceof RetentionAnnotation
        and result = "Containing annotation explicitly specifies Retention, but contained $@ does not"
    )
    or (
        not containingAnnType.getAnAnnotation() instanceof RetentionAnnotation
        and annType.getAnAnnotation() instanceof RetentionAnnotation
        and result = "Containing annotation does not explicitly specify Retention, but contained $@ does"
    )
    // Mismatch between Retention RetentionPolicy values
    or exists(RetentionAnnotation containingAnnRetention, RetentionAnnotation annRetention |
        containingAnnRetention = containingAnnType.getAnAnnotation()
        and annRetention = annType.getAnAnnotation()
    |
        containingAnnRetention.getRetentionPolicy() != annRetention.getRetentionPolicy()
        // Using different @Retention makes repeated annotation being present in class for
        // (or during runtime), while single annotation would not be present, which is most likely not intended
        and result = "Containing annotation uses different Retention than contained $@"
    )
}

from AnnotationType containingAnnType, AnnotationType annType, string message
where
    annType.getAnAnnotation().(RepeatableAnnotation).getContainingType() = containingAnnType
    and message = getMismatchMessage(containingAnnType, annType)
select containingAnnType, message, annType, "@" + annType.getName()
