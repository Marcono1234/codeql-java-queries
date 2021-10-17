/**
 * Finds comparison and equality test expressions which can be simplified.
 * Note that the proposed simplifications could change the behavior regarding
 * numeric overflow.
 * 
 * The following shows some examples which can be simplified:
 * - `-x == -y` → `x == y`
 * - `x + 1 < 4` → `x < 3`
 * - `x - 1 > 0` → `x > 1`
 * - `x * 2 > 4` → `x > 2`
 * - `x / 2.0 > 2` → `x > 4`
 * 
 * However, there can be cases where the verbose expression reported by
 * this query is desired to make the intention clearer, for example
 * `index + 1` to indicate an increment of `index` in the subsequent lines.
 */

import java
import lib.Literals

class ComparisonOrEqualityTest extends BinaryExpr {
    ComparisonOrEqualityTest() {
        this instanceof ComparisonExpr
        or this instanceof EqualityTest
    }
}

class Negated extends Expr {
    Negated() {
        this instanceof MinusExpr
        or this.(MulExpr).getAnOperand().(MinusExpr).getExpr() instanceof LiteralOne
    }
}

from ComparisonOrEqualityTest simplifiableExpr, string action
where
    (
        simplifiableExpr.getLeftOperand() instanceof Negated
        and simplifiableExpr.getRightOperand() instanceof Negated
        and action = "Remove negation from both operands"
    )
    or exists(Literal literalOperand, BinaryExpr simplifiableOperand, Literal removableLiteral |
        literalOperand = simplifiableExpr.getAnOperand()
        and simplifiableOperand = simplifiableExpr.getAnOperand()
        and removableLiteral = simplifiableOperand.getAnOperand()
        // Only consider numeric types, excluding `char`
        and literalOperand.getType() instanceof NumericType
        and removableLiteral.getType() instanceof NumericType
    |
        simplifiableOperand instanceof AddExpr
        and action = "Remove addition and subtract value from literal"
        or
        simplifiableOperand instanceof SubExpr
        and action = "Remove subtraction and add value to literal"
        or
        simplifiableOperand instanceof MulExpr
        and action = "Remove multiplication and divide literal by factor"
        // Only consider when new literal has integral value, or when it was already floating point and
        // new value only needs a few decimal places
        and exists(float newLiteralValue |
            newLiteralValue = getNumericValue(literalOperand) / getNumericValue(removableLiteral)
        |
            // Is integral value
            exists(newLiteralValue.(int))
            or
            literalOperand.getType() instanceof FloatingPointType
            // Has at most two decimal places
            and newLiteralValue.toString().regexpMatch("\\d+(\\.\\d{0,2})?")

        )
        or
        simplifiableOperand instanceof DivExpr
        // Can only simplify when divisor is literal
        and removableLiteral = simplifiableOperand.getRightOperand()
        and action = "Remove division and multiply literal with divisor"
        // And make sure that division is not lossy (i.e. not integral type)
        and simplifiableOperand.getType() instanceof FloatingPointType
    )
select simplifiableExpr, action
