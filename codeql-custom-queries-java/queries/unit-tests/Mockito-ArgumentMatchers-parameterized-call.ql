/**
 * Finds usage of Mockito's `ArgumentMatchers` methods where type arguments
 * are explicitly provided. If the type arguments are not constrained by
 * a method argument (e.g. `Class<T>`) they have no effect at runtime and
 * can be confusing, giving the false expression that Mockito will only
 * match the specified types.
 *
 * Instead the type arguments should be omitted; the compiler will then
 * infer them.
 *
 * For example:
 * ```java
 * // Error-prone: Looks as if this only matches String, but it actually
 * // matches anything
 * // Should instead just use `Mockito.any()`, or `Mockito.anyString()`
 * verify(myObj).doSomething(Mockito.<String>any());
 * ```
 *
 * @kind problem
 * @id TODO
 */

import java

from MethodAccess matcherCall, Method matcherMethod, Expr typeArg
where
  matcherCall.getMethod().getSourceDeclaration() = matcherMethod and
  matcherMethod.getDeclaringType().hasQualifiedName("org.mockito", "ArgumentMatchers") and
  // There is no method parameter which could restrict the type argument (e.g. `Class<T>`)
  matcherMethod.hasNoParameters() and
  // Explicitly specifies type arguments, instead of letting the compiler infer them
  typeArg = matcherCall.getATypeArgument() and
  // Ignore if type arguments are needed to select the correct overload
  not exists(MethodAccess stubbedCall, Method stubbedMethod, int argIndex, SrcMethod overload |
    stubbedCall.getMethod().getSourceDeclaration() = stubbedMethod and
    stubbedCall.getArgument(argIndex) = matcherCall and
    overload.getDeclaringType() =
      stubbedCall.getReceiverType().getSourceDeclaration().getASourceSupertype*() and
    overload.getName() = stubbedMethod.getName() and
    overload.getNumberOfParameters() = stubbedMethod.getNumberOfParameters() and
    overload.getParameterType(argIndex) != stubbedMethod.getParameterType(argIndex) and
    overload != stubbedMethod and
    not overload.isPrivate()
  )
select typeArg, "Explicit type argument should be omitted because it can be misleading"
