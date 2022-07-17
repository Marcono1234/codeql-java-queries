/**
 * Finds expressions in the form `new Date().getTime()`.
 * This should be replaced with `System.currentTimeMillis()`, which behaves
 * exactly the same way.
 * 
 * @kind problem
 */

import java

from ClassInstanceExpr newExpr, MethodAccess getTimeCall
where
  newExpr.getConstructedType().hasQualifiedName("java.util", "Date")
  and newExpr.getNumArgument() = 0
  and getTimeCall.getQualifier() = newExpr
  and getTimeCall.getMethod().hasStringSignature("getTime()")
select newExpr, "Can be replaced with `System.currentTimeMillis()`"
