/**
 * Finds remainder operations (`%`) which use a negative divisor. For the
 * calculation of the remainder the sign of the divisor does not matter,
 * therefore explicitly using a negative divisor might indicate a mistake
 * in the logic.
 */

import java

class RemainderExpr extends Expr {
    Expr divisor;

    RemainderExpr() {
        divisor = this.(RemExpr).getRightOperand()
        or divisor = this.(AssignRemExpr).getRhs()
    }

    Expr getDivisor() {
        result = divisor
    }
}

class NegativeExpr extends Expr {
    NegativeExpr() {
        // Match MinusExpr regardless of its child, because even changing the sign
        // of an unknown value makes no sense for remainder divisor
        this instanceof MinusExpr
        // Or integral literals in decimal notation representing MIN_VALUE
        // (and therefore include the minus)
        or this.(IntegerLiteral).getLiteral().matches("-%")
        or this.(LongLiteral).getLiteral().matches("-%")
        // Also consider plus expressions (despite being unlikely), e.g. `+(-x)`
        or this.(PlusExpr).getExpr() instanceof NegativeExpr
        or this.(CastExpr).getExpr() instanceof NegativeExpr
    }
}

from RemainderExpr r
where
    r.getDivisor() instanceof NegativeExpr
select r, "Uses negative divisor for remainder operation"
