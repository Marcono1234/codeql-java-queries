/**
 * Finds nested unary expressions which are not parenthesized, e.g.:
 * ```
 * int i = 1;
 * // Is equivalent to `-(~(i++))`
 * int r = -~i++;
 * ```
 *
 * The precedence rules for unary expressions are not always that
 * obvious and nested unary expressions can also indicate a typo,
 * e.g. when one operator too much was written, or one operand was
 * left out by accident.
 * For better readability and to explicitly indicate to the person
 * reading the code that it performs as intended, the nested unary
 * expression should be enclosed in parentheses.
 *
 * See also https://docs.oracle.com/javase/tutorial/java/nutsandbolts/operators.html
 */

import java

from UnaryExpr expr, UnaryExpr operand
where
    operand = expr.getExpr()
    and not operand.isParenthesized()
select expr
