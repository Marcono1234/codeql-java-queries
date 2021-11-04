/**
 * Finds usage of `assertThrows` methods where the throwing lambda expression manually
 * causes a test failure (for example by calling `fail()`) when no exception is thrown.
 * Manually causing a test failure is not necessary because the test frameworks will
 * on their own cause a test failure when no exception is thrown. In fact the manually
 * caused assertion error might result in confusing test failures because it will be
 * detected as mismatching exception type by the exception handling of `assertThrows`.
 */

import java
import lib.AssertLib
import lib.TestsQLInterop

from MethodAccess assertThrowsCall, AssertThrowsMethod assertThrowsMethod, LambdaExpr throwingLambda, TestFailingCall testFailingCall
where
    assertThrowsMethod = assertThrowsCall.getMethod()
    and throwingLambda = assertThrowsCall.getArgument(assertThrowsMethod.getExecutableParamIndex())
    and testFailingCall.getEnclosingCallable() = throwingLambda.asMethod()
select testFailingCall, "This call is redundant; assertion method causes failure when no exception is thrown"
