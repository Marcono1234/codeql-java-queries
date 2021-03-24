/**
 * Finds method calls which create an `Optional` from a `null` literal, e.g.:
 * ```java
 * Optional<String> s = Optional.ofNullable(null);
 * ```
 *
 * Instead the respective method for obtaining an empty `Optional` should be
 * used. For `java.util.Optional` that is `Optional.empty()`.
 */

import java
import lib.Optionals

from NewNullableOptionalCallable optionalMethod, MethodAccess call
where
    call.getMethod() = optionalMethod
    and call.getArgument(optionalMethod.getValueParamIndex()) instanceof NullLiteral
select call, "Should use " + optionalMethod.getOptionalType().getEmptyOptionalCallableName()
