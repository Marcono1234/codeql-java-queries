/**
 * Finds calls with an array as argument which can possibly be simplified
 * by omitting indices or the array length argument because there is
 * a method overload which accepts only the array for convenience.
 *
 * For example:
 * ```java
 * out.write(array, 0, array.length)
 * // can be simplified:
 * out.write(array)
 * ```
 *
 * **Important:** Please verify that the alternative suggested by this
 * query behaves the same way. This query does not check the implementation
 * of the proposed alternative but only determines it based on its signature.
 *
 * @kind problem
 */

import java

class ArrayLengthAccess extends FieldRead {
  ArrayLengthAccess() { getField() instanceof ArrayLengthField }
}

from Variable array, Call call, Callable callee, Callable alternative
where
  call.getCallee() = callee and
  // Either `method(array, array.length)` or `method(array, 0, array.length)`
  (
    call.getNumArgument() = 2 and
    call.getArgument(0) = array.getAnAccess() and
    call.getArgument(1).(ArrayLengthAccess).getQualifier() = array.getAnAccess()
    or
    call.getNumArgument() = 3 and
    call.getArgument(0) = array.getAnAccess() and
    call.getArgument(1).(IntegerLiteral).getIntValue() = 0 and
    call.getArgument(2).(ArrayLengthAccess).getQualifier() = array.getAnAccess()
  ) and
  // Altnerative is available on same receiver
  (
    alternative.getDeclaringType() = callee.getDeclaringType().getASourceSupertype*() or
    alternative.getDeclaringType() = call.(MethodAccess).getReceiverType().getASourceSupertype*()
  ) and
  // Alternative has same name and return type, and a single parameter of the same array type
  alternative.getName() = callee.getName() and
  alternative.getReturnType() = callee.getReturnType() and
  alternative.getNumberOfParameters() = 1 and
  alternative.getParameterType(0) = callee.getParameterType(0) and
  // And is same static or non-static as called callable
  (
    callee.isStatic() and alternative.isStatic()
    or
    not callee.isStatic() and not alternative.isStatic()
  ) and
  // And is at least as visible as called callable
  (
    alternative.isPublic()
    or
    callee.isProtected() and alternative.isProtected()
  ) and
  // Don't suggest infinite recursion by calling itself
  not (
    call.getEnclosingCallable() = alternative or
    call.getEnclosingCallable().(Method).getASourceOverriddenMethod*() = alternative
  )
select call, "Could possibly instead call `" + alternative.getStringSignature() + "`"
