/**
 * Finds subtraction expressions where the right operand is a
 * minus expression, e.g.:
 * ```
 * // Equivalent to `i + a + b`
 * int r = i - -(a + b);
 * ```
 *
 * This is equivalent to an addition.
 */

import java


from SubExpr subExpr
where
    subExpr.getRightOperand() instanceof MinusExpr
select subExpr
