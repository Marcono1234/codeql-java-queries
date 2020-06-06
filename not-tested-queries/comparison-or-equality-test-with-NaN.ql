/**
 * Finds comparison expressions and equality tests on NaN (float and double).
 * These tests will either always be true or false due to the floating point
 * arithmetic rules.
 * Use the wrapper class methods (e.g. `java.lang.Float.isNaN​(float)`) to check for NaN.
 */

import java

class NaNRead extends FieldRead {
    NaNRead() {
        getField().getDeclaringType().getQualifiedName() in ["java.lang.Float", "java.lang.Double"]
        and getField().hasName("NaN")
    }
}

from Expr expr
where
    (expr instanceof ComparisonExpr or expr instanceof EqualityTest)
    // ComparisonExpr and EqualityTest are both BinaryExpr
    and expr.(BinaryExpr).getAnOperand() instanceof NaNRead
select expr
