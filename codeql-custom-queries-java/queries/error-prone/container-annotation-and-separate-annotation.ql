/**
 * Finds usage of a container annotation and a separate annotation of the contained
 * repeatable type on the same annotated element.
 * 
 * For example, for the following annotation types:
 * ```java
 * @Repeatable(Markers.class)
 * @interface Marker {
 *     String value();
 * }
 * 
 * @interface Markers {
 *     Marker[] value();
 * }
 * ```
 * 
 * The following usage is detected:
 * ```java
 * @Markers({
 *     @Marker("a"),
 *     @Marker("b")
 * })
 * @Marker("c")
 * String s;
 * ```
 * 
 * Such annotation usage decreases readability and makes the code difficult to understand.
 * Instead the separate annotation (here `@Marker("c")`) should be move to the container
 * annotation, or the explicit usage of the containing annotation type should be removed
 * and all the annotations should directly be placed on the annotated element.
 */

import java

/*
 * Note: The annotation container and the separate annotation are stored in this form in
 * the bytecode and the different between them is therefore detectable using reflection,
 * allowing to convey a different meaning to the program.
 * However, such usage is probably still rather confusing.
 */

from Annotatable annotated, AnnotationType repeatableAnnType, Annotation containingAnn, Annotation separateAnn
where
    annotated.getAnAnnotation() = containingAnn
    and annotated.getAnAnnotation() = separateAnn
    and separateAnn.getType() = repeatableAnnType
    and repeatableAnnType.getAnAnnotation().(RepeatableAnnotation).getContainingType() = containingAnn.getType()
select separateAnn, "This separate annotation should be moved to $@ existing container annotation", containingAnn, "this"
