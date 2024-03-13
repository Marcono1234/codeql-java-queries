/**
 * Finds calls to `assertThrows` and `assertThrowsExactly` where a 'message' argument is provided which
 * seems to be intended as 'expected message'. The 'message' is actually what will be used in case the
 * assertion fails, it is _not_ the expected message for the thrown exception.
 *
 * For example this assertion will pass even though the exception has a different message:
 * ```java
 * assertThrows(
 *     IllegalArgumentException.class,
 *     () -> {
 *         throw new IllegalArgumentException("argument 'actual' is invalid");
 *     },
 *     "argument 'expected' is invalid"
 * );
 * ```
 *
 * @id todo
 * @kind problem
 */

import java

from
  MethodAccess assertThrowsCall, Method assertThrowsMethod, Class expectedException,
  CompileTimeConstantExpr messageArg
where
  assertThrowsCall.getMethod() = assertThrowsMethod and
  // TODO: Use own assertion lib CodeQL classes?
  (
    // JUnit 4
    assertThrowsMethod.getDeclaringType().hasQualifiedName("org.junit", "Assert") and
    assertThrowsMethod.hasName("assertThrows") and
    expectedException = assertThrowsCall.getArgument(1).(TypeLiteral).getReferencedType() and
    messageArg = assertThrowsCall.getArgument(0)
    or
    // JUnit 5
    assertThrowsMethod.getDeclaringType().hasQualifiedName("org.junit.jupiter.api", "Assertions") and
    assertThrowsMethod.hasName(["assertThrows", "assertThrowsExactly"]) and
    expectedException = assertThrowsCall.getArgument(0).(TypeLiteral).getReferencedType() and
    messageArg = assertThrowsCall.getArgument(2)
  ) and
  // Check if anywhere in the code an exception with the exact same message is created
  exists(ConstructorCall newExceptionCall |
    newExceptionCall.getConstructedType().getASourceSupertype*() = expectedException and
    newExceptionCall.getAnArgument().(CompileTimeConstantExpr).getStringValue() =
      messageArg.getStringValue()
  )
select messageArg, "Message argument of `assertThrows` misunderstood as 'expected message'"
