/**
 * Finds calls to the `append(...)` method of `StringBuilder` or `StringBuffer`
 * with a String concatenation expression as argument.
 * String concatenation joins the two Strings and then creates the result
 * String. Since that result is then appended, it would be more efficient to
 * separately append the arguments, which would avoid the intermediate String
 * object.
 * E.g.:
 * ```
 * // Potentially inefficient
 * sb.append("key=" + value);
 * ```
 * Should be written as:
 * ```
 * sb.append("key=").append(value);
 * ```
 */

import java

// TODO: Remove code duplication; already exists in manual-CharSequence-joining.ql
class StringAppendingMethod extends Method {
    StringAppendingMethod() {
        getDeclaringType() instanceof StringBuildingType
        and hasName("append")
    }
}

from AddExpr concatExpr
where
    concatExpr.getType() instanceof TypeString
    and concatExpr.getParent().(MethodAccess).getMethod() instanceof StringAppendingMethod
select concatExpr, "String concatenation as `append(...)` argument"
