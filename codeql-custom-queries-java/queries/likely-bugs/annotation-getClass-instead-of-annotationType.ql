/**
 * Finds calls to `getClass()` on annotation objects. The result will not be the annotation interface
 * type but instead some internal implementation class which implements that interface. Therefore instead
 * [`Annotation#annotationType()`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/lang/annotation/Annotation.html#annotationType())
 * should be used which returns the annotation interface type, or maybe the code can be simplified
 * using `instanceof`, for example `annotation instanceof MyAnnotation`.
 *
 * See also [this Stack Overflow question](https://stackoverflow.com/q/36293911) about
 * the purpose of the `annotationType` method.
 *
 * @kind problem
 * @id TODO
 */

import java

from MethodAccess getClassCall
where
  getClassCall.getMethod().hasStringSignature("getClass()") and
  getClassCall.getReceiverType() instanceof AnnotationType
select getClassCall, "Instead of `getClass()` should prefer `annotationType()`"
