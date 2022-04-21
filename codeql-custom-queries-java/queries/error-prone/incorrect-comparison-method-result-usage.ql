/**
 * Finds incorrect usage of the result of a method performing a comparison and
 * returning an `int`, for example `Comparable.compareTo`. With the exception of
 * a few overrides, these methods usually only define that either a negative or
 * positive value or 0 will be returned, but don't make any guarantees about the
 * exact value. Therefore checking for any specific negative or positive values,
 * or performing any arithmetic operations (even negation of the value) makes the
 * code error-prone because it would depend on the implementation details of the
 * comparison method.
 */

import java
import semmle.code.java.dataflow.DataFlow

import lib.ComparisonLib

predicate isIncorrectUsage(Expr e) {
    // This also considers MinusExpr because in theory result could be Integer.MIN_VALUE, but
    // -Integer.MIN_VALUE is Integer.MIN_VALUE so minus would not have the desired effect
    any(UnaryExpr parent).getExpr() = e
    or exists(BinaryExpr parent |
        parent.getAnOperand() = e
    |
        // Bitwise OR might be used to test whether multiple compared values
        // are all equal (result of OR is 0)
        not parent instanceof OrBitwiseExpr
        and (parent instanceof ComparisonExpr implies exists(boolean isLesser, boolean isStrict, CompileTimeConstantExpr otherOperand, int otherValue |
            otherOperand = parent.getAnOperand()
            and otherOperand != e
            and otherValue = otherOperand.getIntValue()
            and if (parent.(ComparisonExpr).getLesserOperand() = e) then isLesser = true else isLesser = false
            and if (parent.(ComparisonExpr).isStrict()) then isStrict = true else isStrict = false
            // Ignore correct comparison usage
            and not (
                // x < 0 or x < 1
                isLesser = true and isStrict = true and otherValue = [0, 1]
                // x <= -1 or x <= 0
                or isLesser = true and isStrict = false and otherValue = [-1, 0]
                // x > -1 or x > 0
                or isLesser = false and isStrict = true and otherValue = [-1, 0]
                // x >= 0 or x >= 1
                or isLesser = false and isStrict = false and otherValue = [0, 1]
            )
        ))
        and (parent instanceof EqualityTest implies exists(CompileTimeConstantExpr otherOperand |
            otherOperand = parent.getAnOperand()
            and otherOperand != e
            // Comparing with anything other than 0
            and otherOperand.getIntValue() != 0
        ))
        // Ignore string concatenation
        and not parent.(AddExpr).getType() instanceof TypeString
    )
    or exists(AssignOp parent |
        parent.getRhs() = e
        // Bitwise OR might be used to test whether multiple compared values
        // are all equal (result of OR is 0)
        and not parent instanceof AssignOrExpr
        // Ignore string concatenation
        and not parent.(AssignAddExpr).getType() instanceof TypeString
    )
}

from MethodAccess comparisonCall, ComparisonMethod comparisonMethod, Expr incorrectUsage
where
comparisonCall.getMethod() = comparisonMethod
    // Ignore if method defines specific return values
    and not comparisonMethod.definesSpecificReturnValues()
    and isIncorrectUsage(incorrectUsage)
    and DataFlow::localExprFlow(comparisonCall, incorrectUsage)
select incorrectUsage, "Result of $@ comparison is incorrectly used", comparisonCall, "this"
