/**
 * Finds expressions which are enclosed by parentheses but they
 * likely do not improve readability and instead might even confuse
 * other people who are reading the code, e.g.:
 * ```
 * // `a & b` is enclosed twice in parentheses
 * if (((a & b)) == 0) {
 *     ...
 * }
 * ```
 */

import java

/*
 * Only consider cases where there is really no need for parentheses
 * because the expression does not consist of white spaces (e.g. not
 * `X + Y`) and parentheses are not needed for better readability
 *
 * Ignore if expr has qualifier because then author might wanted to
 * increase readability by adding parentheses
 */
predicate doesNotNeedParentheses(Expr expr) {
    (
        expr instanceof ArrayAccess
        and not exists (expr.(ArrayAccess).getArray().(VarAccess).getQualifier())
        // Unary expressions usually have no space between operator and operand,
        // so ignore if operand is parenthesized
        and not expr.getParent() instanceof UnaryExpr
    )
    or expr instanceof InstanceAccess and not exists (expr.(InstanceAccess).getQualifier())
    or expr instanceof MethodAccess and not exists (expr.(MethodAccess).getQualifier())
    or expr instanceof VarAccess and not exists (expr.(VarAccess).getQualifier())
}

from Expr expr
where
    exists (int parentheses | isParenthesized(expr, parentheses) |
        doesNotNeedParentheses(expr)
        // Or expression has multiple parentheses
        or parentheses > 1
    )
select expr
