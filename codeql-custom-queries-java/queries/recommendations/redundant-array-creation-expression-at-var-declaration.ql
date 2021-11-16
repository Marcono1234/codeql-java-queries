/**
 * Finds array creation expressions with array initializer as assigned value for the
 * declaration of a variable.
 * When assigning a variable at its declaration the array creation expression can be
 * omitted.
 * 
 * For example:
 * ```java
 * byte[] bytes = new byte[] {1, 2, 3};
 * ```
 * Can be simplified to:
 * ```java
 * byte[] bytes = {1, 2, 3};
 * ```
 */

import java

// Note: CodeQL always models ArrayCreationExpr even if it is not explicitly written
from Variable var, ArrayCreationExpr arrayCreationExpr
where
    arrayCreationExpr = var.getInitializer()
    and exists(arrayCreationExpr.getInit())
    // Can indentify actual array creation expression by checking for ArrayTypeAccess
    and arrayCreationExpr.getAChildExpr() instanceof ArrayTypeAccess
    // Make sure both have same type, ignore for example `Object o = new String[] {};`
    and var.getType() = arrayCreationExpr.getType()
select var, "Array creation expression `new ...[]` can be omitted"
