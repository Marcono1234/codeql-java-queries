/**
 * Finds array creations with negative constants as dimension, causing
 * a NegativeArraySizeException at runtime.
 */

import java

from ArrayCreationExpr newArrayExpr
where
    newArrayExpr.getADimension().(CompileTimeConstantExpr).getIntValue() < 0
select newArrayExpr
