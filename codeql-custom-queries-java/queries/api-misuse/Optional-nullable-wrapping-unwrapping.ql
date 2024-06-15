/**
 * Finds code which wraps a nullable value in an `Optional` and then directly unwraps it again.
 * Such code can be simplified using for example the methods `requireNonNull`, `requireNonNullElse` or
 * `requireNonNullElseGet` of the class `java.util.Objects`, which avoids having to temporarily wrap
 * the value in an `Optional`.
 *
 * For example:
 * ```java
 * Optional.ofNullable(value).orElse("default-value")
 * // Could be written as
 * Objects.requireNonNullElse(value, "default-value")
 * ```
 *
 * @kind problem
 * @id todo
 */

import java
import lib.Optionals

from Call wrappingCall, MethodAccess unwrappingCall
where
  wrappingCall.getCallee() instanceof NewNullableOptionalCallable and
  unwrappingCall.getQualifier() = wrappingCall and
  // Only consider this when it is directly unwrapped again; ignore for example if `filter(...)` or similar
  // is called first, since rewriting it might make it more verbose
  (
    unwrappingCall.getMethod() instanceof OptionalGetValueMethod or
    unwrappingCall.getMethod() instanceof OptionalOrMethod
  )
select unwrappingCall,
  "Use `Objects.requireNonNullElse` or similar instead of wrapping as `Optional`"
