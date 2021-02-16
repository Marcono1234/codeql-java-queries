/**
 * Finds cases where checked exceptions are 'sneakily' thrown, i.e. they are
 * thrown without them being declared in the `throws` clause of the callable.
 * This is possible because the concept of checked exceptions is only enforced
 * by the compiler, but not by the JVM.
 *
 * While it might be appealing for a method to sneakily throw a checked
 * exception, especially if it overrides an existing method which does not
 * permit throwing checked exceptions, it can cause issues for the caller
 * of that method:
 * - Because the exception is not declared in the `throws` clause, the caller
 *   is likely not aware that it can be thrown. When a sneaky exception is
 *   thrown, this could then cause the exception to propagate way too far up
 *   the call stack before being handled.
 * - The caller might make assumptions based on the `throws` clause about
 *   which checked exceptions can be thrown and perform casts based on that.
 *   If a sneaky exception is encountered this could lead to
 *   ClassCastExceptions or other incorrect behavior.
 * - The compiler only permits `catch` clauses to catch checked exceptions
 *   which are declared by the `throws` clause of the called method. It
 *   might therefore be impossible for the caller to explicitly catch the
 *   sneakily thrown exception. Instead the caller has to catch `Exception`
 *   and then perform complicated exception handling.
 *
 * Due to these disadvantages it should be avoided to sneakily throw checked
 * exceptions. Instead the checked exception should be wrapped in an unchecked
 * one. The JDK already provides useful unchecked exceptions such as
 * `UncheckedIOException` for wrapping checked exceptions. Often there are
 * also alternative methods which permit throwing checked exceptions. For
 * example the `ExecutorService` interface permits submitting `Callable`
 * tasks which can throw checked exceptions.
 */

import java
import semmle.code.java.dataflow.DataFlow

/**
 * Project Lombok's annotation type `SneakyThrows`.
 */
class TypeLombokSneakyThrows extends AnnotationType {
    TypeLombokSneakyThrows() {
        hasQualifiedName("lombok", "SneakyThrows")
    }
}

/**
 * Method which exploits Java type inference quirks to allow throwing any
 * `Throwable` as unchecked exception. Such a method typically looks like this:
 * ```
 * public static <E extends Throwable> void sneakyThrow(Throwable e) throws E {
 *     throw (E) e;
 * }
 * ```
 * (see https://www.baeldung.com/java-sneaky-throws#sneaky)
 */
class SneakilyThrowingMethod extends GenericMethod {
    private Parameter throwableParam;
    
    SneakilyThrowingMethod() {
        exists(TypeVariable throwableTypeVar, CastExpr uncheckedCast, ThrowStmt throwStmt |
            throwableTypeVar = getATypeParameter()
            and throwableParam = getAParameter()
            and throwStmt.getEnclosingCallable() = this
        |
            throwableTypeVar.getUpperBoundType() instanceof TypeThrowable
            and throwableParam.getType().(RefType).getASourceSupertype*() instanceof TypeThrowable
            and getAThrownExceptionType() = throwableTypeVar
            // Unchecked cast of argument to Throwable type parameter
            and throwableParam.getAnAccess().getParent+() = uncheckedCast
            and uncheckedCast.getTypeExpr().getType() = throwableTypeVar
            // Flow from cast to throw statement
            and DataFlow::localFlow(DataFlow::exprNode(uncheckedCast), DataFlow::exprNode(throwStmt.getExpr()))
        )
    }
    
    Parameter getSneakilyThrownParameter() {
        result = throwableParam
    }
}

private Parameter getParameter(Argument arg) {
    result = arg.getCall().getCallee().getParameter(arg.getPosition())
    // Ignore varargs
    and not result.isVarargs()
}

private predicate isSneakilyThrowing(Method m, Parameter param) {
    m.(SneakilyThrowingMethod).getSneakilyThrownParameter() = param
    // Or method delegates to sneakily throwing method
    // Often SneakilyThrowingMethod is not exposed directly due to its
    // potentially irritating generic type parameter
    or exists(MethodAccess sneakilyThrowingCall, Argument throwableArgument |
        sneakilyThrowingCall.getEnclosingCallable() = m
        and throwableArgument = sneakilyThrowingCall.getAnArgument()
    |
        param.getType().(RefType).getASourceSupertype*() instanceof TypeThrowable
        // Only allow a few statements, e.g. for argument validation
        // Cannot use `m.getBody().getNumStmt()` because that only counts immediate
        // child statements
        and count(Stmt stmt | stmt.getEnclosingStmt+() = m.getBody()) <= 3
        and DataFlow::localFlow(DataFlow::parameterNode(param), DataFlow::exprNode(throwableArgument))
        and isSneakilyThrowing(sneakilyThrowingCall.getMethod(), getParameter(throwableArgument))
    )
}

private predicate isSneakilyThrowing(Method m) {
    isSneakilyThrowing(m, m.getAParameter())
}

from Expr sneakilyThrowing
where
    sneakilyThrowing.(Annotation).getType() instanceof TypeLombokSneakyThrows
    or (
        isSneakilyThrowing(sneakilyThrowing.(MethodAccess).getMethod())
        // Don't report intermediate methods
        and not isSneakilyThrowing(sneakilyThrowing.getEnclosingCallable())
    )
select sneakilyThrowing, "Sneakily throws checked exception"
