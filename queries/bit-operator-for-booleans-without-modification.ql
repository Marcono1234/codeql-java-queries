/**
 * Finds usage of the bit operators `&` and `|` which are used for boolean operands
 * where the right operand does not perform any modification, e.g.:
 * ```
 * if (flagA | (flagB & flagC)) {
 *     ...
 * }
 * ```
 * Unlike the short-circuit boolean operators `&&` and `||`, the bit operators
 * always evaluate both operand expressions. Therefore if the right operand does not
 * perform any modification (e.g. assign a value or call a method), using the bit
 * operators is redundant.
 *
 * In general the bit operators should only be used sparingly for boolean operands
 * because they can be confusing to another person reading the code.
 */

import java

class BitwiseBinaryExpr extends BitwiseExpr, BinaryExpr {
    BitwiseBinaryExpr() {
        // XOR does not exist as short circuit, so ignore it
        not this instanceof XorBitwiseExpr
    }
}

from BitwiseBinaryExpr bitwiseExpr
where
    bitwiseExpr.getLeftOperand().getType() instanceof BooleanType
    and bitwiseExpr.getRightOperand().getType() instanceof BooleanType
    // And right operand (or its children) is not performing any modification
    and not exists (Expr child | child.getParent*() = bitwiseExpr.getRightOperand() |
        child instanceof LValue
        or child instanceof Call
    )
select bitwiseExpr
