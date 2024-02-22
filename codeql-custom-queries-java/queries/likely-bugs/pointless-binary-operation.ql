/**
 * Finds binary operations (i.e. expressions with two operands) which have either no effect or
 * always yield the same result. Such operations might indicate a bug or undesired operator
 * precedence.
 * 
 * In some cases such pointless operations are used for symmetry, for example when shifting multiple
 * values by an increasing shift distance, starting at 0. For floating point values in some cases
 * seemingly pointless operations have an effect in some situations, for example the result of
 * `x * 0.0` is zero with the same sign as `x`. Such code should be commented to make the intention
 * clear.
 */

import java
import lib.Literals
import lib.Operations

// TODO: Also cover assign-op, e.g. `x += 0`
// TODO: Also cover bitwise operations, e.g. `| 0`, `| -1`, `& 0` `& -1`
//   (don't have to check if literal is `int` or `long`; e.g. `-1` is implicitly converted to `-1L`)

abstract class PointlessOperation extends Expr {
    abstract string getDescription();
}

class OrFalse extends PointlessOperation {
    OrFalse() {
        this.(OrOperation).getAnOperand().(BooleanLiteral).getBooleanValue() = false
    }

    override
    string getDescription() {
        result = "`OR false` has no effect"
    }
}

class OrTrue extends PointlessOperation {
    OrTrue() {
        this.(OrOperation).getAnOperand().(BooleanLiteral).getBooleanValue() = true
    }

    override
    string getDescription() {
        result = "always `true`"
    }
}

class AndFalse extends PointlessOperation {
    AndFalse() {
        this.(AndOperation).getAnOperand().(BooleanLiteral).getBooleanValue() = false
    }

    override
    string getDescription() {
        result = "always `false`"
    }
}

class AndTrue extends PointlessOperation {
    AndTrue() {
        this.(AndOperation).getAnOperand().(BooleanLiteral).getBooleanValue() = true
    }

    override
    string getDescription() {
        result = "`AND true` has no effect"
    }
}

class ShiftZero extends PointlessOperation {
    ShiftZero() {
        this.(Shift).getShiftedExpr() instanceof LiteralIntegralZero
    }

    override
    string getDescription() {
        result = "always 0"
    }
}

class ShiftByZero extends PointlessOperation {
    ShiftByZero() {
        this.(Shift).getShiftDistance() instanceof LiteralIntegralZero
    }

    override
    string getDescription() {
        result = "shifting by 0 has no effect"
    }
}

class AddZero extends PointlessOperation {
    AddZero() {
        this.(Addition).getAnOperand() instanceof LiteralZero
    }

    override
    string getDescription() {
        result = "`+ 0` has no effect"
    }
}

// One legit use case is keeping sign of floating point value, e.g. `-1 * 0.0` is `-0.0`
class MultiplyZero extends PointlessOperation {
    MultiplyZero() {
        this.(Multiplication).getAnOperand() instanceof LiteralZero
    }

    override
    string getDescription() {
        result = "always 0"
    }
}

class MultiplyOne extends PointlessOperation {
    MultiplyOne() {
        this.(Multiplication).getAnOperand() instanceof LiteralOne
    }

    override
    string getDescription() {
        result = "`* 1` has no effect"
    }
}

class DivideByOne extends PointlessOperation {
    DivideByOne() {
        this.(DividingOperation).getRightOperand() instanceof LiteralOne
    }

    override
    string getDescription() {
        result = "`/ 1` has no effect"
    }
}

class DivideZero extends PointlessOperation {
    DivideZero() {
        this.(DividingOperation).getLeftOperand() instanceof LiteralZero
    }

    override
    string getDescription() {
        result = "always 0"
    }
}

class SubtractZero extends PointlessOperation {
    SubtractZero() {
        this.(Subtraction).getRightOperand() instanceof LiteralZero
    }

    override
    string getDescription() {
        result = "`- 0` has no effect"
    }
}

from PointlessOperation operation
select operation, "Pointless operation: " + operation.getDescription()
