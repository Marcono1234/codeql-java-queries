/**
 * Finds test methods which catch unspecific exception types such as `RuntimeException`
 * and treat them as expected exception without performing any additional checks on the
 * exception, such as verifying the exception message. This makes the test rather
 * error-prone because it might catch a completely unrelated exception causing bugs
 * in the code to go unnoticed.
 * 
 * See also related SonarSource rules [RSPEC-5777](https://rules.sonarsource.com/java/tag/junit/RSPEC-5777)
 * and [RSPEC-5778](https://rules.sonarsource.com/java/tag/junit/RSPEC-5778).
 */

import java
import lib.Tests
import lib.TestsQLInterop
import lib.JUnit4
import lib.AssertLib
import lib.Expressions

class UnspecificExceptionType extends ThrowableType {
    UnspecificExceptionType() {
        // RuntimeException or any superclass
        any(TypeRuntimeException e).getASourceSupertype*() = this
    }
}

from TestMethod testMethod, Top catchingTop, UnspecificExceptionType caughtException
where
    exists(JUnit4TestAnnotation junit4Annotation |
        junit4Annotation = testMethod.getAnAnnotation()
        and catchingTop = junit4Annotation.getExpectedException()
        and catchingTop.(TypeLiteral).getReferencedType() = caughtException
    )
    or exists(TryStmt tryStmt, CatchClause catchClause |
        tryStmt.getEnclosingCallable() = testMethod
        and catchClause = tryStmt.getACatchClause()
        and catchClause.getACaughtType() = caughtException
        and catchingTop = catchClause
        // And variable is not used
        and not exists(catchClause.getVariable().getAnAccess())
        // And catch clause does not exit test method
        and not catchClause.getBlock().(SingletonBlock).getStmt() instanceof TestExitingStmt
    )
    or exists(MethodAccess assertThrowsCall, AssertThrowsMethod assertThrowsMethod |
        assertThrowsCall.getEnclosingCallable() = testMethod
        and assertThrowsMethod = assertThrowsCall.getMethod()
        and (
            // Expects any exception
            not exists(assertThrowsMethod.getExpectedClassParamIndex())
            and caughtException = any(TypeThrowable t)
            // Or expects unspecific exception
            or assertThrowsCall.getArgument(assertThrowsMethod.getExpectedClassParamIndex()).(TypeLiteral).getReferencedType() = caughtException
        )
        and assertThrowsMethod.allowsExceptionSubtypes()
        // And in case caught exception is returned, it is ignored
        and (assertThrowsMethod.returnsException() implies (assertThrowsCall instanceof ValueDiscardingExpr))
        and catchingTop = assertThrowsCall
    )
select catchingTop, "Catches unspecific exception type " + caughtException.getName()
