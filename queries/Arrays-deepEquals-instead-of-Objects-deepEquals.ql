/**
 * Finds calls to `Arrays.deepEquals` where both arguments are new
 * array creation expressions containing a single element, e.g.:
 * ```
 * Arrays.deepEquals(new Object[] {a}, new Object[] {b})
 * ```
 *
 * For Java 7 the method `java.util.Objects.deepEquals` was added
 * which should be used instead.
 */

import java

class ArraysDeepEqualsMethod extends Method {
    ArraysDeepEqualsMethod() {
        getDeclaringType().hasQualifiedName("java.util", "Arrays")
        and hasStringSignature("deepEquals(Object[], Object[])")
    }
}

from MethodAccess call
where
    call.getMethod() instanceof ArraysDeepEqualsMethod
    and strictcount (call.getArgument(0).(ArrayCreationExpr).getInit().getAnInit()) = 1
    and strictcount (call.getArgument(1).(ArrayCreationExpr).getInit().getAnInit()) = 1
select call
