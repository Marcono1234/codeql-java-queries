/**
 * Finds improper handling of `NoSuchAlgorithmException`. Code which catches
 * this exception must properly handle it, e.g. by wrapping and rethrowing it,
 * otherwise it could compromise the security of the application.
 * E.g.:
 * ```java
 * public static String hashPassword(char password) {
 *     try {
 *         ...
 *     } catch (NoSuchAlgorithmException e) {
 *         // BAD: This would result in every password having the same hash
 *         // possibly compromising the security of the complete application
 *         return "";
 *     }
 * }
 * ```
 * 
 * Note that this query is currently not very precise and might report a
 * lot of false positives.
 */

/*
 * Currently rather imprecise because it only considers rethrowing an
 * exception to be proper handling. However, improving precision is difficult
 * because improper handling could have all kinds of pattern, e.g. returning
 * a default or plaintext value, leaving fields uninitialized (causing
 * errors or being interpreted as 'plaintext mode') ...
 */

import java

class TypeNoSuchAlgorithmException extends Class {
    TypeNoSuchAlgorithmException() {
        hasQualifiedName("java.security", "NoSuchAlgorithmException")
    }
}

private predicate catchesNoSuchAlgorithmExceptionOrSupertype(CatchClause catchClause) {
    catchClause.getACaughtType().getASubtype*() instanceof TypeNoSuchAlgorithmException
}

private predicate hasUncaughtNoSuchAlgorithmException(Stmt parentStmt, Call throwingCall) {
    // Need to cast to Expr and use its predicate since transitive closure
    // `throwingCall.getEnclosingStmt+()` would only yield Call elements
    // which are also Stmt (which is not desired)
    throwingCall.(Expr).getAnEnclosingStmt() = parentStmt
    and throwingCall.getCallee().getAThrownExceptionType().getASourceSupertype*() instanceof TypeNoSuchAlgorithmException
    // And exception from throwing call is not caught already
    and not exists(TryStmt nestedTry |
        nestedTry.getEnclosingStmt+() = parentStmt
        and throwingCall.(Expr).getAnEnclosingStmt() = nestedTry
        and catchesNoSuchAlgorithmExceptionOrSupertype(nestedTry.getACatchClause())
    )
}

from CatchClause catchClause
where
    (
        // Explicitly catches NoSuchAlgorithmException
        catchClause.getACaughtType().getASourceSupertype*() instanceof TypeNoSuchAlgorithmException
        // Or catches supertype and call which throws NoSuchAlgorithmException
        // is inside try statement
        or exists(TryStmt tryStmt, int catchClauseIndex | catchClause = tryStmt.getCatchClause(catchClauseIndex) |
            catchesNoSuchAlgorithmExceptionOrSupertype(catchClause)
            and hasUncaughtNoSuchAlgorithmException(tryStmt.getBlock(), _)
            // Ignore if a previous catch clause already caught the exception
            and not exists(CatchClause otherCatchClause |
                otherCatchClause = tryStmt.getACatchClause()
                and otherCatchClause.getIndex() < catchClauseIndex
            |
                catchesNoSuchAlgorithmExceptionOrSupertype(otherCatchClause)
            )
        )
    )
    // Only consider exception as properly handled when exception is rethrown
    and not any(ThrowStmt t).getEnclosingStmt+() = catchClause.getBlock()
    // Ignore test classes
    and not catchClause.getEnclosingCallable().getDeclaringType() instanceof TestClass
select catchClause, "Might not properly handle NoSuchAlgorithmException"
