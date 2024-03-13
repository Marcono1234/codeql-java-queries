/**
 * Finds comparison and equality test expressions which can be simplified.
 * Note that the proposed simplifications could change the behavior regarding
 * numeric overflow.
 * 
 * The following shows some examples which can be simplified:
 * - `-x == -y` → `x == y`
 * - `x - y > 0` → `x > y`
 * - `x + 1 < 4` → `x < 3`
 * - `x - 1 > 0` → `x > 1`
 * - `x * 2 > 4` → `x > 2`
 * - `x / 2.0 > 2` → `x > 4`
 * 
 * However, there can be cases where the verbose expression reported by
 * this query is desired to make the intention clearer, for example
 * `index + 1` to indicate an increment of `index` in the subsequent lines.
 * 
 * @id todo
 * @kind problem
 */

import java
import lib.Expressions
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
    or exists(SubExpr subExpr, int compared, boolean equalOrGreater, string recommendedCmpOp |
        comparesWithConstant(simplifiableExpr, subExpr, compared, equalOrGreater)
        and (
            recommendedCmpOp = ">="
            // compares `>= 0`
            and compared = 0
            and equalOrGreater = true
            or
            recommendedCmpOp = ">"
            // compares `>= 1`
            and compared = 1
            and equalOrGreater = true
            // ignore floating point values because it can have results between 0 and 1
            and subExpr.getType() instanceof IntegralType
            or
            recommendedCmpOp = "<"
            // compares `< 0`
            and compared = 0
            and equalOrGreater = false
            or
            recommendedCmpOp = "<="
            // compares `< 1`
            and compared = 1
            and equalOrGreater = false
            // ignore floating point values because it can have results between 0 and 1
            and subExpr.getType() instanceof IntegralType
        )
    |
        action = "Remove subtraction and directly compare values: `a " + recommendedCmpOp + " b`"
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
