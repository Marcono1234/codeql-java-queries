/**
 * Finds usage of `sun.misc.Unsafe` methods with arrays as argument where the
 * 'offset' argument is not based on `Unsafe.ARRAY_..._BASE_OFFSET`. This most likely
 * means that the code is by accident either reading or overwriting the header value
 * at the start of the array object, which could corrupt it.
 *
 * @kind problem
 * @id todo
 */

import java

from MethodAccess unsafeCall, Method unsafeMethod, int arrayArgIndex, Expr badOffsetArg
where
  unsafeCall.getMethod() = unsafeMethod and
  unsafeMethod.getDeclaringType().hasQualifiedName("sun.misc", "Unsafe") and
  unsafeCall.getArgument(arrayArgIndex).getType() instanceof Array and
  // For all existing `Unsafe` reading and writing methods there is first the `Object` parameter
  // and then directly afterwards the `long` 'offset' parameter
  unsafeMethod.getParameterType(arrayArgIndex + 1).hasName("long") and
  badOffsetArg = unsafeCall.getArgument(arrayArgIndex + 1) and
  (
    // If it is a constant, then it is not based on `Unsafe.ARRAY_..._BASE_OFFSET` because those
    // values are currently not compile time constants in the `Unsafe` implementation
    badOffsetArg instanceof CompileTimeConstantExpr
    or
    // Or variable where all assigned values are constant (and therefore not based on `Unsafe.ARRAY_..._BASE_OFFSET`)
    // Require that `v.getInitializer()` exists to ignore variables with implicit assigned value, e.g. method parameters
    // (TODO: This is not completely correct because this excludes local variables which are initalized by a separate assignment)
    exists(Variable v | v = badOffsetArg.(RValue).getVariable() and exists(v.getInitializer()) |
      forex(Expr e | e = v.getAnAssignedValue() | e instanceof CompileTimeConstantExpr)
    )
  )
select badOffsetArg, "'offset' argument is missing base offset for array"
