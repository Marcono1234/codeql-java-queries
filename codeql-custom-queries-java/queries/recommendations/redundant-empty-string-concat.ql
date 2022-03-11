/**
 * Finds redundant string concatentations with empty strings. Often string concatenations
 * with empty strings are used to convert values to string, e.g. `number + ""`. However,
 * if the other operand of the concatenation is already a string, then concatenating it
 * with an empty string is most likely redundant (unless the value might be `null`).
 */

import java

Expr getLeftmostExpr(Expr e) {
    if e instanceof AddExpr
    then result = getLeftmostExpr(e.(AddExpr).getLeftOperand())
    else result = e
}

Expr getRightmostExpr(Expr e) {
    if e instanceof AddExpr
    then result = getRightmostExpr(e.(AddExpr).getRightOperand())
    else result = e
}

from AddExpr concatExpr, StringLiteral emptyString, Expr otherOp
where
    emptyString.getValue() = ""
    and otherOp.getType() instanceof TypeString
    and (
        (
            emptyString = concatExpr.getLeftOperand()
            and otherOp = concatExpr.getRightOperand()
            // Make sure that expression directly after `+` is a string, e.g. to exclude `"" + (1 + "text")`
            and getLeftmostExpr(otherOp).getType() instanceof TypeString
        )
        or (
            emptyString = concatExpr.getRightOperand()
            and otherOp = concatExpr.getLeftOperand()
            // Make sure that expression directly before `+` is a string, e.g. to exclude `"text" + 1 + ""`
            and getRightmostExpr(otherOp).getType() instanceof TypeString
        )
    )
select concatExpr, "Redundant string concatentation with empty string"
