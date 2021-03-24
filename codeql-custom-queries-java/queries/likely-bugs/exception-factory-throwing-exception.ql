/**
 * Finds lambda expressions and methods which appear supposed to be an exception
 * factory, but instead of returning the created exception, they throw it.
 * E.g.:
 * ```java
 * private IOException createException(String file, String message) {
 *     // Should return this exception instead of throwing it
 *     throw new IOException("Operation on file " + file + " failed: " + message);
 * }
 * ```
 *
 * Sometimes libraries throw the exception on purpose. However in these cases
 * this often provides no advantage because the caller then also has to use
 * a `throw` statement on the 'result' so that the compiler understands that
 * the execution terminates there. Therefore the factory method could simply
 * return the exception instead as well.
 */

import java

private predicate hasThrowableReturnType(Method m) {
    m.getReturnType().(RefType).getASourceSupertype*() instanceof TypeThrowable
}

class TypeUnsupportedOperationException extends Class {
    TypeUnsupportedOperationException() {
        hasQualifiedName("java.lang", "UnsupportedOperationException")
    }
}

// Needed due to https://github.com/github/codeql/issues/5464
private RefType getAThrowsClauseType(Callable c) {
    exists(Exception e | e = c.getAnException() |
        e.fromSource()
        and result = e.getType()
    )
}

// Could make this more accurate by verifying that throw statements only throw exceptions
// of same type (or subtype) as return type, or RuntimeException or Error (possibly as
// part of error handling); though this might also reduce true positives
private predicate isNotProperExceptionFactory(Method m) {
    exists(ThrowStmt t | t.getEnclosingCallable() = m |
        // Ignore UnsupportedOperationException, might indicate that factory method
        // is not supported
        not t.getThrownExceptionType() instanceof TypeUnsupportedOperationException
    )
    and forall(ThrowStmt t | t.getEnclosingCallable() = m |
        // And there is no `throws` clause declaring that exception is thrown
        // In that case method is likely designed to throw exception
        not t.getThrownExceptionType().getASourceSupertype*() = getAThrowsClauseType(m)
    )
    // And does not have any return statement; throw statement might otherwise
    // for example be part of argument validation
    and not any(ReturnStmt r).getEnclosingCallable() = m
}

from Element factoryMethod
where
    exists(LambdaExpr lambda | lambda = factoryMethod |
        // Lambda seems supposed to return Throwable (or subtype)
        hasThrowableReturnType(lambda.asMethod())
        and isNotProperExceptionFactory(lambda.asMethod())
    )
    or exists(Method method | method = factoryMethod |
        // Method seems supposed to return Throwable (or subtype)
        hasThrowableReturnType(method)
        and isNotProperExceptionFactory(method)
        // Prevent reporting implicit method of lambda; instead prefer reporting LambdaExpr
        and not any(LambdaExpr l).asMethod() = method
    )
select factoryMethod, "Seems supposed to be an exception factory, but instead of returning exception, throws it"
