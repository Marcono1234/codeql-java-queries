/**
 * Finds non-0 dimension expressions after a 0 dimension expression for an
 * array creation.
 * Those non-0 dimension expressions have no effect on the created array,
 * which indicates that the code might not behave the way it was originally
 * designed:
 * `new int[0][10][getSize()]` is the same as
 * ```
 * getSize()
 * new int[0][][];
 * ```
 */

import java

class ZeroConstant extends CompileTimeConstantExpr {
    ZeroConstant() {
        getIntValue() = 0 
    }
}

from ArrayCreationExpr newArrayExpr
where
    exists (ZeroConstant zeroDimExpr, Expr otherDimExpr |
        zeroDimExpr = newArrayExpr.getADimension()
        and otherDimExpr = newArrayExpr.getADimension()
        // otherDimExpr appears behind 0 dim expression
        and zeroDimExpr.getIndex() < otherDimExpr.getIndex()
        and not otherDimExpr instanceof ZeroConstant
    )
select newArrayExpr