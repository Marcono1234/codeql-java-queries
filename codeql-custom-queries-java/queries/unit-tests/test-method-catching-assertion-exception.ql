/**
 * Finds test methods which treat `AssertionError` or a superclass as expected exception.
 * This can lead to accidentally catching exceptions from failed assertions in the
 * test method. For example:
 * ```java
 * try {
 *     doSomething();
 *     fail("Exception should have been thrown");
 * }
 * // Bad: This also catches the exception from `fail(...)`
 * catch (Throwable expected) { }
 * ```
 * 
 * See SonarSource rules [RSPEC-5777](https://rules.sonarsource.com/java/tag/junit/RSPEC-5777)
 * and [RSPEC-5779](https://rules.sonarsource.com/java/tag/junit/RSPEC-5779).
 */

import java
import lib.Tests
import lib.TestsQLInterop
import lib.JUnit4

class TypeAssertionError extends Class {
    TypeAssertionError() {
        hasQualifiedName("java.lang", "AssertionError")
    }
}

predicate performsAssertion(BlockStmt block) {
    exists(ThrowStmt throwStmt |
        throwStmt.getExpr().getType().(RefType).getASourceSupertype*() instanceof TypeAssertionError
        and throwStmt.getEnclosingStmt+() = block
    )
    or any(AssertStmt a).getEnclosingStmt+() = block
    or exists(MethodAccess assertionCall |
        assertionCall.getMethod() instanceof AssertionMethod
        and assertionCall.getAnEnclosingStmt() = block
    )
    or exists(Call call |
        call.getEnclosingStmt+() = block
        and performsAssertion(call.getCallee().getBody())
    )
}

class AssertionErrorOrSupertype extends Class {
    AssertionErrorOrSupertype() {
        any(TypeAssertionError e).getASourceSupertype*() = this
    }
}

from TestMethod testMethod, Top catchingTop
where
    exists(JUnit4TestAnnotation junit4Annotation |
        junit4Annotation = testMethod.getAnAnnotation()
        // Reduce false positives by making sure method actually performs assertion
        and performsAssertion(testMethod.getBody())
        and catchingTop = junit4Annotation.getExpectedException()
        and catchingTop.(TypeLiteral).getReferencedType() instanceof AssertionErrorOrSupertype
    )
    or exists(TryStmt tryStmt, CatchClause catchClause |
        tryStmt.getEnclosingCallable() = testMethod
        and catchClause = tryStmt.getACatchClause()
        and catchClause.getACaughtType() instanceof AssertionErrorOrSupertype
        // Reduce false positives by making sure `try` body actually performs assertion
        and performsAssertion(tryStmt.getBlock())
        and catchingTop = catchClause
        // And variable is not used
        and not exists(catchClause.getVariable().getAnAccess())
        // And catch clause does not exit test method
        and not catchClause.getBlock().(SingletonBlock).getStmt() instanceof TestExitingStmt
    )
select catchingTop, "Caught exception might hide exceptions from failed assertions"
