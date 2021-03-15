/**
 * Finds plus expressions with non-literal operand, e.g.:
 * ```
 * // `+i` has no effect but might be misleading
 * int result = +i * 2;
 * ```
 *
 * The plus operator has no effect other than performing a numeric promotion on
 * the operand.
 * However, it might give the false impression that it returns the absolute value
 * or guarantees that the value is positive, which is both **not the case**.
 * Therefore the plus operator should be avoided for non-literals.
 *
 * See also https://docs.oracle.com/javase/specs/jls/se14/html/jls-15.html#jls-15.15.3
 */

import java


from PlusExpr plusExpr
where
    not plusExpr.getExpr() instanceof Literal
select plusExpr
