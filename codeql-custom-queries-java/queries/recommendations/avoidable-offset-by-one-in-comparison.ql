/**
 * Finds `+ 1` or `- 1` as part of a comparison expression operand which can be
 * avoided by changing the strictness of the comparison operator. Note that the
 * proposed simplifications could change the behavior regarding numeric overflow.
 * 
 * For example with `x` having an integral type:
 * - `x + 1 > y` → `x >= y`
 * - `x - 1 >= y` → `x > y`
 * - `x + 1 <= y` → `x < y`
 * - `x - 1 < y` → `x <= y`
 * 
 * However, there can be cases where the verbose expression reported by
 * this query is desired to make the intention clearer, for example
 * `index + 1` to indicate an increment of `index` in the subsequent lines.
 */

import java
import lib.Literals

string getStrictnessToggledOperator(ComparisonExpr e) {
    e instanceof LEExpr and result = "<"
    or e instanceof LTExpr and result = "<="
    or e instanceof GEExpr and result = ">"
    or e instanceof GTExpr and result = ">="
}

from ComparisonExpr comparisonExpr, BinaryExpr simplifiableOperand, boolean isLesserOperand, boolean isStrict, string toRemove
where
    (
        isLesserOperand = true and simplifiableOperand = comparisonExpr.getLesserOperand()
        or isLesserOperand = false and simplifiableOperand = comparisonExpr.getGreaterOperand()
    )
    and if comparisonExpr.isStrict() then isStrict = true else isStrict = false
    and exists(Expr modifiedOperand, LiteralOne offsetLiteral |
        modifiedOperand = simplifiableOperand.getAnOperand()
        and offsetLiteral = simplifiableOperand.getAnOperand()
        and modifiedOperand != offsetLiteral
        // Simplification only works for integral types (including `char`)
        and modifiedOperand.getType() instanceof IntegralType
    |
        simplifiableOperand instanceof AddExpr
        and toRemove = "+ 1"
        and (
            // `x + 1 >`
            isLesserOperand = false and isStrict = true
            // `x + 1 <=`
            or isLesserOperand = true and isStrict = false
        )
        or
        // Can only simplify `- 1`, but not `1 -`
        offsetLiteral = simplifiableOperand.(SubExpr).getRightOperand()
        and toRemove = "- 1"
        and (
            // `x - 1 >=`
            isLesserOperand = false and isStrict = false
            // `x - 1 <`
            or isLesserOperand = true and isStrict = true
        )
    )
select comparisonExpr, "Remove `" + toRemove + "` from $@ and change the comparison operator to `" + getStrictnessToggledOperator(comparisonExpr) + "`",
    simplifiableOperand, "this operand"
