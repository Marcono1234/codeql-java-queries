/**
 * Finds calls to `String.join` with only two arguments to join, instead of performing
 * string concatenation.
 *
 * For example:
 * ```java
 * String.join("-", a, b)
 * // can be simplified to
 * a + "-" + b
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
  joinMethod.isVarargs() and
  // Separator + 2 varargs args
  joinCall.getNumArgument() = 3
select joinCall, "Can be replaced with string concatenation"
