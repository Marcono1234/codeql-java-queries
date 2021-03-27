/**
 * Finds cases where a `javax.crypto.BadPaddingException` is not properly handled.
 * When decrypting, merely the information that the padding is invalid can be abused
 * by an adversary for a [padding oracle attack](https://en.wikipedia.org/wiki/Padding_oracle_attack).
 * Therefore great care should be taken when handling a BadPaddingException. When
 * it occurs in an implementation for encrypted network traffic, the response to the
 * user should be the same as if data was properly encrypted, but did not have the
 * expected value, preventing the user from seeing whether or not he padding was
 * valid.
 */

import java

class TypeBadPaddingException extends Class {
    TypeBadPaddingException() {
        hasQualifiedName("javax.crypto", "BadPaddingException")
    }
}

class PaddingExceptionThrowingCallable extends Callable {
    PaddingExceptionThrowingCallable() {
        // Don't check for subtypes because throwing AEADBadTagException is not
        // problematic since AEAD is not vulnerable to padding oracle attacks (?)
        getAThrownExceptionType() instanceof TypeBadPaddingException
    }
}

private predicate catchesPaddingException(TryStmt try, Expr throwingExpr) {
    throwingExpr.getAnEnclosingStmt() = try.getBlock()
    // Catches BadPaddingException or supertype
    and try.getACatchClause().getACaughtType().getASubtype*() instanceof TypeBadPaddingException
}

private predicate hasUncaughtPaddingException(Stmt parentStmt, Call throwingCall) {
    // Need to cast to Expr and use its predicate since transitive closure
    // `throwingCall.getEnclosingStmt+()` would only yield Call elements
    // which are also Stmt (which is not desired)
    throwingCall.(Expr).getAnEnclosingStmt() = parentStmt
    and throwingCall.getCallee() instanceof PaddingExceptionThrowingCallable
    // And exception from throwing call is not caught already
    and not exists(TryStmt nestedTry |
        nestedTry.getEnclosingStmt+() = parentStmt
        and catchesPaddingException(nestedTry, throwingCall)
    )
}

from Top badExceptionHandling, string message
where
    exists(TryStmt try, CatchClause catch, RefType caughtType |
        badExceptionHandling = catch
        and message = "Catches BadPaddingException or supertype but might not handle it properly"
    |
        catch = try.getACatchClause()
        and caughtType = catch.getACaughtType()
        and (
            // Catches BadPaddingException
            caughtType instanceof TypeBadPaddingException
            // Or supertype of BadPaddingException is caught and `try`
            // calls method which throws BadPaddingException
            or (
                caughtType.getASubtype+() instanceof TypeBadPaddingException
                // And there is not another `catch` which already caught exception
                and not exists(CatchClause priorCatch |
                    priorCatch = try.getACatchClause()
                    and priorCatch.getIndex() < catch.getIndex()
                    and priorCatch.getACaughtType().getASubtype*() instanceof TypeBadPaddingException
                )
                and hasUncaughtPaddingException(try.getBlock(), _)
            )
        )
        and (
            // If caught exception is used in any way, this special handling might be noticable
            // by caller which could allow padding oracle attack
            exists(catch.getVariable().getAnAccess())
            // Or catch rethrows an exception; merely the fact that an exception is thrown
            // might allow padding oracle attack
            or exists(ThrowStmt throw | throw.getEnclosingStmt+() = catch.getBlock())
        )
    )
    or exists(Callable callable |
        badExceptionHandling = callable
        and message = "Has `throws` clause which hides that BadPaddingException is thrown"
    |
        // Declares `throws` BadPaddingException supertype
        callable.getAThrownExceptionType().getASubtype+() instanceof TypeBadPaddingException
        and hasUncaughtPaddingException(callable.getBody(), _)
    )
select badExceptionHandling, message
