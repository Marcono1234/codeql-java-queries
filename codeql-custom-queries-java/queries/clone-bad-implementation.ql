/**
 * Finds implementations of `clone()` which behave in a bad or incorrect
 * way. Currently covered are the cases that they declare to throw
 * `CloneNotSupportedException` but actually throw a different exception,
 * and that they return `null` (which violates the method contract).
 *
 * Note however, that in general it is discouraged to implement `Cloneable`
 * or use `clone()` in the first place, see also CodeQL query
 * `java/use-of-cloneable-interface`.
 */


import java

class TypeCloneNotSupportedException extends Class {
    TypeCloneNotSupportedException() {
        hasQualifiedName("java.lang", "CloneNotSupportedException")
    }
}

from CloneMethod cloneMethod, Stmt badStmt, string message
where
    badStmt.getEnclosingCallable() = cloneMethod
    and (
        (
            message = "Throws exception other than CloneNotSupportedException"
            // Only consider if `throws` clause lists exception, otherwise cannot be thrown
            // because it is a checked exception
            and cloneMethod.getAThrownExceptionType() instanceof TypeCloneNotSupportedException
            and badStmt instanceof ThrowStmt
            and not badStmt.(ThrowStmt).getThrownExceptionType().getASourceSupertype*() instanceof TypeCloneNotSupportedException
        )
        or message = "Returns null despite it not being allowed"
        and badStmt.(ReturnStmt).getResult() instanceof NullLiteral
    )
select badStmt, message
