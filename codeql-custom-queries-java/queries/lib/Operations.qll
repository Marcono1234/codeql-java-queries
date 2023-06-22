import java

abstract class BinaryOperation extends Expr {
    abstract Expr getLeftOperand();
    abstract Expr getRightOperand();

    Expr getAnOperand() {
        result = [
            getLeftOperand(),
            getRightOperand()
        ]
    }
}

abstract class OrOperation extends BinaryOperation {
}

abstract class AndOperation extends BinaryOperation {
}

class OrLogical extends OrOperation {
    Expr rightOperand;

    OrLogical() {
        rightOperand = this.(OrLogicalExpr).getRightOperand()
    }

    override
    Expr getLeftOperand() {
        result = this.(OrLogicalExpr).getLeftOperand()
    }

    override
    Expr getRightOperand() {
        result = rightOperand
    }
}

class AndLogical extends AndOperation {
    Expr rightOperand;

    AndLogical() {
        rightOperand = this.(AndLogicalExpr).getRightOperand()
    }

    override
    Expr getLeftOperand() {
        result = this.(AndLogicalExpr).getLeftOperand()
    }

    override
    Expr getRightOperand() {
        result = rightOperand
    }
}

class OrBitwise extends OrOperation {
    Expr rightOperand;

    OrBitwise() {
        rightOperand = [
            this.(OrBitwise).getRightOperand(),
            this.(AssignOrExpr).getRhs()
        ]
    }

    override
    Expr getLeftOperand() {
        result = this.(OrBitwiseExpr).getLeftOperand()
    }

    override
    Expr getRightOperand() {
        result = rightOperand
    }
}

class AndBitwise extends AndOperation {
    Expr rightOperand;

    AndBitwise() {
        rightOperand = [
            this.(AndBitwiseExpr).getRightOperand(),
            this.(AssignAndExpr).getRhs()
        ]
    }

    override
    Expr getLeftOperand() {
        result = this.(AndBitwiseExpr).getLeftOperand()
    }

    override
    Expr getRightOperand() {
        result = rightOperand
    }
}


class XorBitwise extends BinaryOperation {
    Expr rightOperand;

    XorBitwise() {
        rightOperand = [
            this.(XorBitwiseExpr).getRightOperand(),
            this.(AssignXorExpr).getRhs()
        ]
    }

    override
    Expr getLeftOperand() {
        result = this.(XorBitwiseExpr).getLeftOperand()
    }

    override
    Expr getRightOperand() {
        result = rightOperand
    }
}

abstract class Shift extends BinaryOperation {
    Expr getShiftedExpr() {
        result = getLeftOperand()
    }

    Expr getShiftDistance() {
        result = getRightOperand()
    }
}

class LeftShift extends Shift {
    Expr rightOperand;

    LeftShift() {
        rightOperand = [
            this.(LeftShiftExpr).getRightOperand(),
            this.(AssignLeftShiftExpr).getRhs()
        ]
    }

    override
    Expr getLeftOperand() {
        result = this.(LeftShiftExpr).getLeftOperand()
    }

    override
    Expr getRightOperand() {
        result = rightOperand
    }
}

class RightShift extends Shift {
    Expr rightOperand;

    RightShift() {
        rightOperand = [
            this.(RightShiftExpr).getRightOperand(),
            this.(AssignRightShiftExpr).getRhs()
        ]
    }

    override
    Expr getLeftOperand() {
        result = this.(RightShiftExpr).getLeftOperand()
    }

    override
    Expr getRightOperand() {
        result = rightOperand
    }
}

class URightShift extends Shift {
    Expr rightOperand;

    URightShift() {
        rightOperand = [
            this.(UnsignedRightShiftExpr).getRightOperand(),
            this.(AssignUnsignedRightShiftExpr).getRhs()
        ]
    }

    override
    Expr getLeftOperand() {
        result = this.(UnsignedRightShiftExpr).getLeftOperand()
    }

    override
    Expr getRightOperand() {
        result = rightOperand
    }
}


class Addition extends BinaryOperation {
    Expr rightOperand;

    Addition() {
        rightOperand = [
            this.(AddExpr).getRightOperand(),
            this.(AssignAddExpr).getRhs()
        ]
    }

    override
    Expr getLeftOperand() {
        result = this.(AddExpr).getLeftOperand()
    }

    override
    Expr getRightOperand() {
        result = rightOperand
    }
}

class Multiplication extends BinaryOperation {
    Expr rightOperand;

    Multiplication() {
        rightOperand = [
            this.(MulExpr).getRightOperand(),
            this.(AssignMulExpr).getRhs()
        ]
    }

    override
    Expr getLeftOperand() {
        result = this.(MulExpr).getLeftOperand()
    }

    override
    Expr getRightOperand() {
        result = rightOperand
    }
}


abstract class DividingOperation extends BinaryOperation {
}

class Division extends DividingOperation {
    Expr rightOperand;

    Division() {
        rightOperand = [
            this.(DivExpr).getRightOperand(),
            this.(AssignDivExpr).getRhs()
        ]
    }

    override
    Expr getLeftOperand() {
        result = this.(DivExpr).getLeftOperand()
    }

    override
    Expr getRightOperand() {
        result = rightOperand
    }
}

class Remainder extends DividingOperation {
    Expr rightOperand;

    Remainder() {
        rightOperand = [
            this.(RemExpr).getRightOperand(),
            this.(AssignRemExpr).getRhs()
        ]
    }

    override
    Expr getLeftOperand() {
        result = this.(RemExpr).getLeftOperand()
    }

    override
    Expr getRightOperand() {
        result = rightOperand
    }
}

class Subtraction extends BinaryOperation {
    Expr rightOperand;

    Subtraction() {
        rightOperand = [
            this.(SubExpr).getRightOperand(),
            this.(AssignSubExpr).getRhs()
        ]
    }

    override
    Expr getLeftOperand() {
        result = this.(SubExpr).getLeftOperand()
    }

    override
    Expr getRightOperand() {
        result = rightOperand
    }
}
