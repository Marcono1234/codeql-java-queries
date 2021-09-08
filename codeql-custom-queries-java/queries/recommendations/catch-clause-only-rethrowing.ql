/**
 * Finds `catch` clauses which just contain a single `throw` statement rethrowing the caught
 * exception. For example:
 * ```java
 * try {
 *     ...
 * } catch (IOException ioException) {
 *     throw ioException;
 * }
 * ```
 * Without any additional comment the above code adds no value and might
 * confuse readers.
 */

import java

from CatchClause catchClause, SingletonBlock catchBlock, ThrowStmt throwStmt
where
    catchBlock = catchClause.getBlock()    
    and catchBlock.getStmt() = throwStmt
    and throwStmt.getExpr() = catchClause.getVariable().getAnAccess()
    // And there is no comment in the catch block
    // Javadoc matches regular comments as well, see https://github.com/github/codeql/issues/3695
    and not exists(Javadoc comment, Location catchBlockLocation |
        not exists(comment.getCommentedElement())
        and catchBlockLocation = catchBlock.getLocation()
        and comment.getLocation().getStartLine() in [catchBlockLocation.getStartLine() .. catchBlockLocation.getEndLine()]
    )
    // And all caught exceptions are checked; otherwise the explicit `throw` might
    // be used to indicate that the fact this unchecked exception type can be thrown
    // was considered, but it was decided to not handle it
    and forall(RefType caughtType | caughtType = catchClause.getACaughtType() |
        not caughtType instanceof UncheckedThrowableType
    )
    // And there is no subsequent catch clause of the same `try` statement
    // (otherwise that might catch the exception)
    and not exists(TryStmt parentTryStmt, CatchClause otherCatchClause |
        parentTryStmt.getACatchClause() = catchClause
        and parentTryStmt.getACatchClause() = otherCatchClause
        and otherCatchClause.getIndex() > catchClause.getIndex()
    )
    // And there is not enclosing `try` statement; otherwise (similar to unchecked
    // exceptions above) the `throw` might be intended to indicate that the exception
    // can occur in the inner `try` statement
    and not exists(TryStmt enclosingTryStmt |
        enclosingTryStmt.getBlock() = catchBlock.getEnclosingStmt*()
    )
select throwStmt, "Rethrows caught exception"
