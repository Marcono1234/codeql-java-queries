/**
 * Finds usage of inherited annotations on interfaces. Annotation types marked with `@Inherited`
 * are only inherited when the annotation is used on classes; they have no effect when an
 * annotation is used on interfaces, see [`@Inherited` documentation](https://docs.oracle.com/en/java/javase/16/docs/api/java.base/java/lang/annotation/Inherited.html).
 * 
 * Note that this query is not very precise because often programs only use annotation
 * inheritance as additional feature, but the annotation itself on an interface has a
 * meaning to the program as well.
 * 
 * @kind problem
 * @precision low
 */

import java

from Interface interface, Annotation annotation
where
    interface.fromSource()
    and interface.getAnAnnotation() = annotation
    and annotation.getType().isInherited()
select annotation, "Inherited annotations do not work for interfaces"
