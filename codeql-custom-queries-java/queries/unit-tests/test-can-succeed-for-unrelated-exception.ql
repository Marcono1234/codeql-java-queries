/**
 * Finds test methods which use `try`-`catch` to test for expected exceptions, but where the
 * `try` block contains multiple calls which might throw the expected exception. For example:
 * ```java
 * try {
 *     // Unclear whether doAction1 or doAction2 cause the expected exception
 *     doAction1();
 *     doAction2();
 *     fail();
 * } catch (IOException expected) {
 * }
 * ```
 * Ideally only call the method which is supposed to throw the exception inside the `try` block
 * and perform everything else outside of it. Additionally it might also be useful to be as
 * specific as possible with the expected exception (e.g. `IOException` instead of just `Exception`)
 * and to also check the message of the exception (unless it is created by third-party code).
 * 
 * See also SonarSource rules
 * - [RSPEC-5778](https://rules.sonarsource.com/java/RSPEC-5778)
 * - [RSPEC-5783](https://rules.sonarsource.com/java/RSPEC-5783)
 * 
 * @kind problem
 */

// TODO: Also cover assertThrows (or write separate query)

import java
import lib.TestsQLInterop

predicate isTestMethod(Callable callable) {
    (
        callable instanceof TestMethod
        // Check if method is inside test class, might be utility method
        // then which is used by test methods
        or exists (RefType type | type = callable.getDeclaringType() |
            type instanceof TestClass
            and type.isTopLevel()
            and type.getCompilationUnit() = callable.getCompilationUnit()
        )
    )
    // Ignore teardown methods
    and not callable instanceof TeardownMethod
}

// TODO: Avoid code duplication with queries/javadoc/documented-unchecked-thrown-exception-not-inherited.ql
ThrowableType getExceptionClass(string exceptionName, CompilationUnit compilationUnit) {
    // Currently does not check precedence in case type is ambiguous, but should suffice for
    // most cases
    result.hasQualifiedName("java.lang", exceptionName)
    or result.hasQualifiedName(compilationUnit.getPackage().getName(), exceptionName)
    or exists(Import import_ |
        import_.getCompilationUnit() = compilationUnit
        and result.getName() = exceptionName
    |
        result = [
            import_.(ImportOnDemandFromPackage).getAnImport(),
            import_.(ImportOnDemandFromType).getAnImport(),
            import_.(ImportStaticOnDemand).getATypeImport(),
            import_.(ImportStaticTypeMember).getATypeImport()
        ]
    )
}

ThrowableType getAThrownExceptionType(Callable c) {
    result = c.getAThrownExceptionType()
    or exists(ThrowsTag throwsTag |
        throwsTag.getParent+().(Javadoc).getCommentedElement() = c
        and result = getExceptionClass(throwsTag.getExceptionName(), c.getCompilationUnit())
    )
}

from TryStmt try, BlockStmt tryBlock, CatchClause catch, ThrowableType caughtExceptionType
where
    isTestMethod(try.getEnclosingCallable())
    and tryBlock = try.getBlock()
    and tryBlock.getLastStmt().(ExprStmt).getExpr() instanceof TestFailingCall
    and catch = try.getACatchClause()
    // Usually block is empty when exception is expected; ignore if it performs assertions on the caught exception,
    // then it might be less likely that the wrong exception causes the test to pass
    and catch.getBlock().getNumStmt() = 0
    and caughtExceptionType = catch.getACaughtType()
    and count(Call c |
        c.(Expr).getAnEnclosingStmt() = tryBlock
        and getAThrownExceptionType(c.getCallee()).getASourceSupertype*() = caughtExceptionType
        and not c.(Expr).getParent*() instanceof TestFailingCall
        // Ignore if this is a (redundant) assert call, that is covered by separate query
        and not c.getCallee() instanceof AssertionMethod
    ) > 1
select tryBlock, "Has multiple calls which might throw " + caughtExceptionType.getName()
