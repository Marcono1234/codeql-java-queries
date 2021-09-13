import java
private import JUnit4
private import JUnit5
private import TestNg

/**
 * Annotation type used to mark a method for performing setup of a test class.
 */
abstract class SetupAnnotationType extends AnnotationType {
}

/**
 * Annotation type used to mark a method for performing teardown of a test class.
 */
abstract class TeardownAnnotationType extends AnnotationType {
}

/**
 * Gets the enclosing method of the expression. If the method is inside a lambda expression
 * gets the enclosing method of the lambda, recursively.
 */
Method getEnclosingNonLambdaMethod(Expr e) {
    // When inside lambda get method enclosing lambda
    if exists(LambdaExpr l | l.asMethod() = e.getEnclosingCallable())
    then exists(LambdaExpr l | l.asMethod() = e.getEnclosingCallable() and result = getEnclosingNonLambdaMethod(l))
    else result = e.getEnclosingCallable()
}
