/**
 * Finds assignments with a plus or minus expression on the right side
 * where it appears the intentation was to use a compound assignment
 * instead, e.g.:
 * ```
 * // Developer made a typo and wrote `=+` instead of `+=`
 * for (int i = 0; i < x; i =+ 2) {
 *   ...
 * }
 * ```
 */

import java

// Based on https://bugs.openjdk.java.net/browse/JDK-4965337

class PlusOrMinusExpr extends UnaryExpr {
    PlusOrMinusExpr() {
        this instanceof PlusExpr
        or this instanceof MinusExpr
    }
}

from AssignExpr assignExpr, Expr destExpr, Location destLoc, PlusOrMinusExpr plusOrMinusExpr, Location plusOrMinusLoc
where
    destExpr = assignExpr.getDest()
    and destLoc = destExpr.getLocation()
    and plusOrMinusExpr = assignExpr.getRhs()
    // Make sure left and right side of assignment are on same line
    // Otherwise cannot make reliable statement about how far right side
    // is away from `=`
    and destLoc.getEndLine() = plusOrMinusLoc.getStartLine()
    // Check if there is no space on one side of `=`, e.g. `a =- 1`
    // Could cause false positives if there is no space between dest
    // and `=` (e.g. `a= -1`), but there is not way to detect that
    and if plusOrMinusExpr.isParenthesized() then (
        plusOrMinusLoc.getStartColumn() - destLoc.getEndColumn() < 5
    ) else (
        plusOrMinusLoc.getStartColumn() - destLoc.getEndColumn() < 4
    )
    and plusOrMinusLoc = plusOrMinusExpr.getLocation()
    // There is a space between plus/minus and its expr, e.g. `- 1`
    and exists (Expr rhs, Location rhsLoc | rhs = plusOrMinusExpr.getExpr() and rhsLoc = rhs.getLocation() |
        rhsLoc.getStartLine() != plusOrMinusLoc.getStartLine()
        or if rhs.isParenthesized() then (
            rhsLoc.getStartColumn() - plusOrMinusLoc.getStartColumn() > 2
        ) else (
            rhsLoc.getStartColumn() - plusOrMinusLoc.getStartColumn() > 1
        )
    )
select assignExpr, plusOrMinusExpr
