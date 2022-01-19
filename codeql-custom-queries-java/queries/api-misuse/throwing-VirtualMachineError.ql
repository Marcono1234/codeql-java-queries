/**
 * Finds code which throws a `java.lang.VirtualMachineError` or a subtype of it. The
 * documentation of the class says:
 * > Thrown to indicate that the Java Virtual Machine is broken or has run out of resources necessary for it to continue operating.
 * 
 * Therefore, it is almost never appropriate to throw such an error manually. If
 * the thrown error is used to indicate an unreachable code path, it may be more
 * appropriate to throw a `java.lang.RuntimeException` or `java.lang.AssertionError` instead.
 */

// Bug report describing JDK misuse of InternalError: https://bugs.openjdk.java.net/browse/JDK-6194382

import java

from ThrowStmt throwStmt, RefType thrownType
where
   thrownType = throwStmt.getThrownExceptionType()
   and thrownType.getASourceSupertype*().hasQualifiedName("java.lang", "VirtualMachineError")
   // Ignore throwing OutOfMemoryError; sometimes this is done when reaching array length limit
   // (though that behavior is also questionable)
   and not thrownType.getASourceSupertype*().hasQualifiedName("java.lang", "OutOfMemoryError")
select throwStmt, "Throws VirtualMachineError or subtype of it"
