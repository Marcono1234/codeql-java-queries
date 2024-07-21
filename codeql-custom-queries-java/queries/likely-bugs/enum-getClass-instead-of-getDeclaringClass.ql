/**
 * Finds calls to `getClass()` on enum values. If an enum constant implements or overrides methods,
 * it is created as anonymous class. In this case `getClass()` will return that anonymous class,
 * which is often undesired. Instead
 * [`Enum#getDeclaringClass()`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/lang/Enum.html#getDeclaringClass())
 * should be used.
 *
 * @kind problem
 * @id TODO
 */

import java

from MethodAccess getClassCall
where
  getClassCall.getMethod().hasStringSignature("getClass()") and
  getClassCall.getQualifier().getType() instanceof EnumType and
  // Ignore own method access, then it is either intentional or at least risk of incorrect behavior
  // is reduced since implementation of enum is in the same file
  not getClassCall.isOwnMethodAccess()
select getClassCall, "Instead of `getClass()` should prefer `getDeclaringClass()`"
