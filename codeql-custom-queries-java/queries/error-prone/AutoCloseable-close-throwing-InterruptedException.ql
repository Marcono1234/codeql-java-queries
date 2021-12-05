/**
 * Finds methods which override `AutoCloseable.close()` and throw an `InterruptedException` in
 * it. The documentation of `AutoCloseable.close()` recommends against doing this because when
 * the `AutoCloseable` is used in a try-with-resources statement the thrown `InterruptedException`
 * might be suppressed and therefore prevent actually interrupting the thread.
 * 
 * A solution to this can be to wrap the `InterruptedException` and instead set the interrupted
 * status again by calling `Thread.currentThread().interrupt()`.
 */

import java

class ExprOrStmt extends ExprParent {
    Callable getEnclosingCallable() {
        result = [
            this.(Expr).getEnclosingCallable(),
            this.(Stmt).getEnclosingCallable()
        ]
    }
    
    Stmt getAnEnclosingStmt() {
        result = [
            this.(Expr).getAnEnclosingStmt(),
            this.(Stmt).getEnclosingStmt+()
        ]
    }
}

class AutoCloseableCloseMethod extends Method {
    AutoCloseableCloseMethod() {
        getDeclaringType().hasQualifiedName("java.lang", "AutoCloseable")
        and hasStringSignature("close()")
    }
}

class TypeInterruptedException extends RefType {
    TypeInterruptedException() {
        hasQualifiedName("java.lang", "InterruptedException")
    }
}

ExprOrStmt getThrowingElement(Method closeMethod) {
    result.getEnclosingCallable() = closeMethod
    and exists(RefType exceptionType |
        exceptionType.getASourceSupertype*() instanceof TypeInterruptedException
    |
        (
            exists(ThrowStmt throwStmt |
                throwStmt = result
                and throwStmt.getEnclosingCallable() = closeMethod
            |
                exceptionType = throwStmt.getThrownExceptionType()
            )
            or exists(Call call |
                call = result
                and call.getEnclosingCallable() = closeMethod
            |
                exceptionType = call.getCallee().getAThrownExceptionType()
            )
        )
        // Ignore if exception is handled by try-catch
        and not exists(TryStmt tryStmt |
            tryStmt.getBlock() = result.getAnEnclosingStmt()
            and tryStmt.getACatchClause().getACaughtType() = exceptionType.getASourceSupertype*()
        )
    )
}

from Method closeMethod, Top reportedElement, string message
where
    closeMethod.getSourceDeclaration().getASourceOverriddenMethod*() instanceof AutoCloseableCloseMethod
    and (
        reportedElement = getThrowingElement(closeMethod)
        and message = "Throws InterruptedException in close() method"
        or
        exists(Exception declaredException |
            declaredException = closeMethod.getAnException()
            and declaredException.getType().getASourceSupertype*() instanceof TypeInterruptedException
            // Ignore thrown exceptions, see https://github.com/github/codeql/issues/5464
            and declaredException.fromSource()
        )
        and message = "Declares InterruptedException or subtype to be thrown"
    )
select reportedElement, message
