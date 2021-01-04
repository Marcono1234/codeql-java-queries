/**
 * Finds add expressions which perform an arithmetic addition, but due
 * to missing parentheses look like they are part of a String concatentation, e.g.:
 * ```
 * // Prints "195c" because it is essentially ('a' + 'b') + "c"
 * System.out.println('a' + 'b' + "c");
 * ```
 */

import java

// Operators are evaluated left to right, therefore only String on the
// right might be confusing; String on the left would create String concat
AddExpr getStringConcatOnRight(AddExpr add) {
    not add.isParenthesized()
    // Use if-then-else to prevent duplicate results when there are multiple subsequent
    // concat expressions
    and if (add.getParent().(AddExpr).getRightOperand().getType() instanceof TypeString) then (
        result = add.getParent()
    ) else result = getStringConcatOnRight(add.getParent())
}

from AddExpr addExpr, AddExpr concatExpr
where
    // Add is not a String concat
    not addExpr.getType() instanceof TypeString
    and concatExpr = getStringConcatOnRight(addExpr)
select addExpr, "Performs arithmetic addition, but due to missing parentheses looks like it belongs to $@ String concat.", concatExpr, "this"
