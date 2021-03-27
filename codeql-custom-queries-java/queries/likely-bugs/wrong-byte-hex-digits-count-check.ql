/**
 * Finds comparison expressions which appear to check how many
 * hexadecimal digits a `byte` value would have by comparing it
 * with 15, respectively 16.
 * However, because `byte` is signed, such checks are likely flawed.
 * Instead they should check the unsigned value `b & 0xFF`.
 * E.g.:
 * ```java
 * public static int getHexDigitsCount(byte b) {
 *     // BAD: Byte is signed so negative values would erroneously
 *     // be reported as having only one hex digit
 *     // Should instead check unsigned value: `(b & 0xFF) < 16`
 *     return b < 16 : 1 ? 2;
 * }
 * ```
 */

// Note: Could reduce false positives by ignoring cases where two
// comparison expressions limit range, e.g. `b >= 0 && b <= 15`

import java

class ByteType extends Type {
    ByteType() {
        exists(PrimitiveType p |
            p = this or p = this.(BoxedType).getPrimitiveType()
        |
            p.hasName("byte")
        )
    }
}

from ComparisonExpr compExpr, Expr byteExpr
where
    byteExpr.getType() instanceof ByteType
    and (
        // < 16
        (
            compExpr.isStrict()
            and byteExpr = compExpr.getLesserOperand()
            and compExpr.getGreaterOperand().(CompileTimeConstantExpr).getIntValue() = 16
        )
        // <= 15
        or (
            not compExpr.isStrict()
            and byteExpr = compExpr.getLesserOperand()
            and compExpr.getGreaterOperand().(CompileTimeConstantExpr).getIntValue() = 15
        )
        // > 15
        or (
            compExpr.isStrict()
            and compExpr.getLesserOperand().(CompileTimeConstantExpr).getIntValue() = 15
            and byteExpr = compExpr.getGreaterOperand()
        )
        // >= 16
        or (
            not compExpr.isStrict()
            and compExpr.getLesserOperand().(CompileTimeConstantExpr).getIntValue() = 16
            and byteExpr = compExpr.getGreaterOperand()
        )
    )
    // Ignore if byte value is a counter variable
    and not exists(Variable var | byteExpr = var.getAnAccess() |
        any(UnaryAssignExpr e).getExpr() = var.getAnAccess()
    )
select compExpr, "Might incorrectly check hex digits count of signed byte value"
