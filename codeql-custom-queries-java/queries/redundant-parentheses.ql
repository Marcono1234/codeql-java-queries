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

predicate isOnRightSide(Expr ancestor, Expr child) {
    exists (Expr rightSide | 
        (
            rightSide = ancestor.(BinaryExpr).getRightOperand()
            or rightSide = ancestor.(UnaryExpr).getExpr()
            or rightSide = ancestor.(CastExpr).getExpr()
            or rightSide = ancestor.(Assignment).getRhs()
        )
        and (
            child = rightSide
            or isOnRightSide(rightSide, child)
        )
    )
}

/*
 * Only consider cases where there is really no need for parentheses
 * because the expression does not consist of white spaces (e.g. not
 * `X + Y`) and parentheses are not needed for better readability
 *
 * Ignore if expr has qualifier because then author might wanted to
 * increase readability by adding parentheses
 */
predicate doesNotNeedParentheses(Expr expr) {
    // Expression parents where expr is the only child and nothing else
    // follows on the right side of it
    (
        exists (Stmt parent | parent = expr.getParent() |
            parent instanceof ReturnStmt
            or parent instanceof YieldStmt
            or parent instanceof ThrowStmt
            or parent instanceof SynchronizedStmt
            or parent instanceof ExprStmt
            or parent instanceof AssertStmt and not exists (parent.(AssertStmt).getMessage())
        )
        // Only consider if there are potentially confusing parentheses
        // as child expr, e.g. `assert (arg != null)` is fine, but
        // `return ((int) (i + getElement(0)))` is not
        and exists (Expr child | child.getParent+() = expr |
            child.isParenthesized()
            or child instanceof CastExpr
            // Call has arguments
            or child.(Call).getNumArgument() > 0
            // Or call with 0 args is on right side of parenthesized expr
            or isOnRightSide(expr, child.(Call))
        )
    )
    or (
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
        (
            doesNotNeedParentheses(expr)
            // Only consider if expr does not span multiple lines, otherwise parentheses
            // _can_ improve readability (though not always)
            and expr.getLocation().getStartLine() = expr.getLocation().getEndLine()
        )
        // Or expression has multiple parentheses
        or parentheses > 1
    )
select expr
