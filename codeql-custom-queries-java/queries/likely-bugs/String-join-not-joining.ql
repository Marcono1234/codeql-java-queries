/**
 * Finds calls to `String.join` with no or only one argument to join. In that case no joining
 * is actually performed.
 *
 * For example:
 * ```java
 * // is equivalent to just `a` (respectively `String.valueOf(a)`)
 * String.join("-", a)
 * ```
 *
 * @id todo
 * @kind problem
 */

import java

from MethodAccess joinCall, Method joinMethod
where
  joinCall.getMethod() = joinMethod and
  joinMethod.getDeclaringType() instanceof TypeString and
  joinMethod.hasName("join") and
  joinMethod.isStatic() and
  // Only cover the varargs overload `String.join(CharSequence, CharSequence...)`
  joinMethod.isVarargs() and
  (
    joinCall.getNumArgument() = 1
    or
    joinCall.getNumArgument() = 2 and
    not joinCall.getArgument(1).getType() instanceof Array
  )
select joinCall, "Does not perform any joining"
