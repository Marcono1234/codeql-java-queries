/**
 * Finds javadoc block tags which were likely be meant to be annotation
 * usage examples. The `javadoc` tool considers an `@` (optionally prefixed
 * with spaces) at the beginning of a documentation comment line as block
 * tag, even if it appears within a `{@code ...}` inline tag spanning multiple
 * lines. The `@` should therefore be written as HTML character entity
 * reference `&commat;` or `&#64;`.
 */

import java

from JavadocTag javadocTag, string potentialAnnotationName
where
    potentialAnnotationName = javadocTag.getTagName().suffix(1)
    and exists (AnnotationType annotationType |
        potentialAnnotationName = annotationType.getName()
        or potentialAnnotationName = annotationType.getQualifiedName()
    )
select javadocTag, javadocTag.getTagName()
