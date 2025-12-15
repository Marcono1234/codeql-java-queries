/**
 * Finds method parameters where always the same field with the same name as the parameter is used
 * as argument for that parameter.
 * It could improve readability to remove the parameter and directly access the field in the
 * method.
 *
 * For example:
 * ```java
 * class MyCollection<E> {
 *     int size;
 *
 *     public E removeLast() {
 *         // Note: Passes the field to the instance method
 *         if (isEmpty(size)) {
 *             ...
 *         }
 *         ...
 *     }
 *
 *     // Note: Uses the parameter instead of directly the field
 *     private boolean isEmpty(size) {
 *         return size == 0;
 *     }
 * }
 * ```
 *
 * Could be written as:
 * ```java
 * ...
 *     public E popLast() {
 *         if (isEmpty()) {
 *             ...
 *         }
 *         ...
 *     }
 *
 *     private boolean isEmpty() {
 *         return size == 0;
 *     }
 * ...
 * ```
 *
 * Note that if the field is reassigned while the method is running (possibly concurrently, or directly
 * or indirectly by the method), then switching to direct field access within the method could lead to
 * an undesired behavior change.
 *
 * @kind problem
 * @id TODO
 */

import java

from Method m, Parameter p, int pIndex, Field f
where
  p = m.getParameter(pIndex) and
  // Only consider if param and field have same name; using same field regardless of name
  // could be coincidence and maybe future code changes will use other args
  f.getName() = p.getName() and
  // Field must be accessible by method, otherwise cannot refactor it to directly access field
  // (e.g. if method is only called by subclasses and field is declared in subclass,
  // cannot refactor method)
  // Note: Don't have to explicitly check field or method visibility; given that there are calls
  // to the method with the field as argument it is most likely also accessible directly by method
  f.getDeclaringType() = m.getDeclaringType().getASourceSupertype*() and
  // Ignore if parameter is reassigned, switching to direct field access would be behavior change
  not p.getAnAccess().isVarWrite() and
  forex(MethodCall call | call.getMethod().getSourceDeclaration() = m |
    (
      // Either not in varargs position
      pIndex < m.getNumberOfParameters() - 1
      or
      // Or there is only a single argument for varargs (or parameter is not varargs)
      call.getNumArgument() = m.getNumberOfParameters()
    ) and
    exists(FieldRead fRead | fRead = call.getArgument(pIndex) and fRead.getField() = f |
      f.isStatic()
      or
      // Note: Could also cover "instance field for static method", in which case the method
      // could be turned into an instance method, but maybe that should be a separate query?
      fRead.isOwnFieldAccess() and call.isOwnMethodCall()
    )
  ) and
  // Ignore cases where omitting the parameters from the method signature is not possible
  not m.isAbstract() and
  not m.overrides(_) and
  // And is not overridden
  not exists(Method override | override.getAnOverride() = m)
select p, "Can omit method parameter and directly access $@ in method", f, "field of same name"
