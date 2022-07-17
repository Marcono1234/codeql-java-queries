/**
 * Finds expressions in the form `new Date(System.currentTimeMillis())`.
 * This should be replaced with `new Date()`, which behaves exactly the
 * same way.
 * 
 * @kind problem
 */

import java

from ClassInstanceExpr newExpr, Method currentTimeMethod
where
    newExpr.getConstructedType().hasQualifiedName("java.util", "Date")
    and newExpr.getNumArgument() = 1
    and newExpr.getArgument(0).(MethodAccess).getMethod() = currentTimeMethod
    and currentTimeMethod.getDeclaringType() instanceof TypeSystem
    and currentTimeMethod.hasStringSignature("currentTimeMillis()")
select newExpr, "Can be replaced with `new Date()`"
