/**
 * Finds usage of nullness annotations, such as `@NotNull`, on annotation elements.
 * Such annotations are redundant because annotation elements cannot have `null` values
 * (unless the annotation type is manually implemented as interface).
 * 
 * @kind problem
 */

import java

import lib.Nullness

from AnnotationElement element, NullnessAnnotation annotation
where
    element.getAnAnnotation() = annotation
    or exists (TypeAccess t |
        t.getParent+() = element
        and annotation = t.getAnAnnotation()
    )
    // TODO: CodeQL does not support getting annotations from ArrayTypeAccess yet?
    // See also https://github.com/github/codeql/issues/3417
    /*
    or exists (ArrayTypeAccess t |
        t.getParent+() = element
        and annotation = t.getAnAnnotation()
    )
    */
select annotation, "Nullness annotation for annotation element is redundant"
