/**
 * Finds explicit usage of a containing annotation which could be omitted and
 * whose contained repeated annotations could directly be used as annotation
 * on the annotated element.
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
 * This code
 * ```java
 * @Markers({
 *     @Marker("a"),
 *     @Marker("b")
 * })
 * String s;
 * ```
 * Could be replaced with:
 * ```java
 * @Marker("a")
 * @Marker("b")
 * String s;
 * ```
 * 
 * Note that in some cases explicit usage of the containing annotation might be useful
 * to increase readability by grouping annotations.
 */

import java
import lib.Annotations

from Annotation containingAnn
where
    // Only include results from source; ignore implicit containing annotations
    containingAnn.getCompilationUnit().fromSource()
    // Verify it is a containing annotation type
    and any (RepeatableAnnotation a).getContainingType() = containingAnn.getType()
    // Ignore if containing annotation has additional elements (even if they have default values)
    // because suggesting to remove containing annotation might be a behavior change
    and not exists (AnnotationElement otherElem |
        otherElem = containingAnn.getType().getAnAnnotationElement()
        and otherElem.getName() != "value"
    )
    // Verify that contained annotations is not empty
    and exists (containingAnn.getAValue("value"))
    /*
     * Note: In theory there could be a difference in behavior when only a single annotation
     * is contained and the containing annotation type has different settings than the type of
     * the contained annotation
     * However, such a configuration is detected by `containing-annotation-different-settings-than-contained.ql`
     */
select containingAnn, "Can omit this annotation and directly repeat contained annotations"
