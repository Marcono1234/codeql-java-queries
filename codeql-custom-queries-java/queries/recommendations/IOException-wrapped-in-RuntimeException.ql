/**
 * Finds code which wraps an `IOException` in a `RuntimeException`. It might be better to
 * wrap the exception in an `UncheckedIOException` (added in Java 8) which is more specific
 * than the base class `RuntimeException`.
 * 
 * @kind problem
 */

import java

from ClassInstanceExpr newRuntimeException
where
    newRuntimeException.getConstructedType() instanceof TypeRuntimeException
    // Only consider IOException but not subclasses, for them UncheckedIOException might not fit much better
    and newRuntimeException.getAnArgument().getType().(RefType).hasQualifiedName("java.io", "IOException")
    and not newRuntimeException.getEnclosingCallable().getDeclaringType() instanceof TestClass
select newRuntimeException, "Should wrap IOException in UncheckedIOException"
