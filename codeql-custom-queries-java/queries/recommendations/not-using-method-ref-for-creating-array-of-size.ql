/**
 * Finds usage of a lambda expression for creating an array of a requested size,
 * for example `size -> new String[size]`. This can be replaced with a method
 * reference expression performing an array creation, for example `String[]::new`.
 */

import java

from LambdaExpr lambda, Method lambdaMethod, ArrayCreationExpr arrayCreation
where
    // Lambda only creates array
    (
        arrayCreation = lambda.getExprBody()
        or arrayCreation = lambda.getStmtBody().(SingletonBlock).getStmt().(ReturnStmt).getResult()
    )
    and lambdaMethod = lambda.asMethod()
    and lambdaMethod.getNumberOfParameters() = 1
    and arrayCreation.getDimension(0) = lambdaMethod.getParameter(0).getAnAccess()
    // Only first dimension is specified, other ones (if any) are blank, e.g. `new int[size][][];`
    and not exists(int dimensionIndex | dimensionIndex > 0 and exists(arrayCreation.getDimension(dimensionIndex)))
select lambda, "Can be replaced with " + arrayCreation.getType() + "::new"
