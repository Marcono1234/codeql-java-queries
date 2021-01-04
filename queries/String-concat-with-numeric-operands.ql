/**
 * Finds add expressions which perform String concatenation with
 * two numeric operands. Often this is caused by accident, and even
 * if this is intended it can confuse readers:
 * ```
 * int index = 2;
 * // Prints "Position 21" because it is essentially ("Position: " + index) + 1
 * System.out.println("Position: " + index + 1);
 * ```
 */

import java

from AddExpr concatExpr, AddExpr leftConcatExpr
where
    // Add performs String concat
    concatExpr.getType() instanceof TypeString
    // Because operators are evaluated left to right have to check right operand
    // of left concat and right operand of this concat
    // E.g. (with implicit parentheses): ("a" + 1) + 2
    // Note: NumericType does not include `char`; this is good because `char` should be excluded
    and leftConcatExpr = concatExpr.getLeftOperand()
    // Ignore if left concat is parenthesized, then it is explicit that String
    // concat is desired, e.g. (explicit parentheses): ("a" + 1) + 2
    and not leftConcatExpr.isParenthesized()
    and leftConcatExpr.getRightOperand().getType() instanceof NumericType
    and concatExpr.getRightOperand().getType() instanceof NumericType
select concatExpr, "Misleading String concat with numeric operands."
