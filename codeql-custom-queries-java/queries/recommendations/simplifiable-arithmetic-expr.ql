/**
 * Finds arithmetic expressions which can be simplified.
 * 
 * @kind problem
 * @precision low
 */

// Similar to CodeQL's `java/complex-boolean-expression`

import java

abstract class SimplifiableArithExpr extends Expr {
    abstract string getCurrent();
    abstract string getRecommendation();
}

/*
 * TODO:
 * - Ignore casts (similar to how sign is ignored)
 */

class NegativeExpr extends Expr {
    NegativeExpr() {
        this instanceof MinusExpr
        // Or integral literals in decimal notation representing MIN_VALUE
        // (and therefore include the minus)
        or this.(IntegerLiteral).getLiteral().matches("-%")
        or this.(LongLiteral).getLiteral().matches("-%")
        or this.(CastExpr).getExpr() instanceof NegativeExpr
    }
}

class AddingMinus extends SimplifiableArithExpr, AddExpr {
    AddingMinus() {
        getRightOperand() instanceof NegativeExpr
        // Ignore string concatenation
        and not getType() instanceof TypeString
    }

    override
    string getCurrent() { result = "x + (-y)" }

    override
    string getRecommendation() { result = "x - y" }
}

class AssignAddingMinus extends SimplifiableArithExpr, AssignAddExpr {
    AssignAddingMinus() {
        getRhs() instanceof NegativeExpr
        // Ignore string concatenation
        and not getType() instanceof TypeString
    }

    override
    string getCurrent() { result = "x += (-y)" }

    override
    string getRecommendation() { result = "x -= y" }
}

class SubtractingMinus extends SimplifiableArithExpr, SubExpr {
    SubtractingMinus() {
        getRightOperand() instanceof NegativeExpr
    }

    override
    string getCurrent() { result = "x - (-y)" }

    override
    string getRecommendation() { result = "x + y" }
}

class AssignSubtractingMinus extends SimplifiableArithExpr, AssignSubExpr {
    AssignSubtractingMinus() {
        getRhs() instanceof NegativeExpr
    }

    override
    string getCurrent() { result = "x -= (-y)" }

    override
    string getRecommendation() { result = "x += y" }
}

class MultiplyingBothNegative extends SimplifiableArithExpr, MulExpr {
    MultiplyingBothNegative() {
        getLeftOperand() instanceof NegativeExpr
        and getRightOperand() instanceof NegativeExpr
    }

    override
    string getCurrent() { result = "-x * -y" }

    override
    string getRecommendation() { result = "x * y" }
}

class DividingBothNegative extends SimplifiableArithExpr, DivExpr {
    DividingBothNegative() {
        getLeftOperand() instanceof NegativeExpr
        and getRightOperand() instanceof NegativeExpr
    }

    override
    string getCurrent() { result = "-x / -y" }

    override
    string getRecommendation() { result = "x / y" }
}

class SignExpr extends UnaryExpr {
    SignExpr() {
        this instanceof MinusExpr
        or this instanceof PlusExpr
    }
}

class One extends Expr {
    One() {
        this.(IntegerLiteral).getIntValue() = 1
        or this.(LongLiteral).getValue() = "1"
        or this.(FloatLiteral).getValue() = "1.0"
        or this.(DoubleLiteral).getValue() = "1.0"
        or this.(SignExpr).getExpr() instanceof One
        or this.(CastExpr).getExpr() instanceof One
    }
}

class InversingExpr extends Expr {
    InversingExpr() {
        this.(DivExpr).getLeftOperand() instanceof One
        or this.(SignExpr).getExpr() instanceof InversingExpr
        or this.(CastExpr).getExpr() instanceof InversingExpr
    }
}

class MultiplyingInverse extends SimplifiableArithExpr, MulExpr {
    MultiplyingInverse() {
        getAnOperand() instanceof InversingExpr
    }

    override
    string getCurrent() { result = "x * (1 / y)" }

    override
    string getRecommendation() { result = "x / y" }
}

class AssignMultiplyingInverse extends SimplifiableArithExpr, AssignMulExpr {
    AssignMultiplyingInverse() {
        getRhs() instanceof InversingExpr
    }

    override
    string getCurrent() { result = "x *= (1 / y)" }

    override
    string getRecommendation() { result = "x /= y" }
}

class DividingInverse extends SimplifiableArithExpr, DivExpr {
    DividingInverse() {
        getRightOperand() instanceof InversingExpr
    }

    override
    string getCurrent() { result = "x / (1 / y)" }

    override
    string getRecommendation() { result = "x * y" }
}

class AssignDividingInverse extends SimplifiableArithExpr, AssignDivExpr {
    AssignDividingInverse() {
        getRhs() instanceof InversingExpr
    }

    override
    string getCurrent() { result = "x /= (1 / y)" }

    override
    string getRecommendation() { result = "x *= y" }
}

class NonInversingFraction extends Expr {
    NonInversingFraction() {
        // Division which is not `1 / ...`
        (this instanceof DivExpr and not this instanceof InversingExpr)
        or this.(SignExpr).getExpr() instanceof NonInversingFraction
        or this.(CastExpr).getExpr() instanceof NonInversingFraction
    }
}

/**
 * `x / (y / z)`; it might be easier to read by converting it to
 * multiplication and using inverse of fraction.
 */
class DividingByFraction extends SimplifiableArithExpr, DivExpr {
    DividingByFraction() {
        getRightOperand() instanceof NonInversingFraction
    }

    override
    string getCurrent() {
        result = "x / (y / z)"
    }

    override
    string getRecommendation() {
        result = "x * (z / y)"
    }
}

class AssignDividingByFraction extends SimplifiableArithExpr, AssignDivExpr {
    AssignDividingByFraction() {
        getRhs() instanceof NonInversingFraction
    }

    override
    string getCurrent() { result = "x /= (y / z)" }

    override
    string getRecommendation() { result = "x *= (z / y)" }
}

from SimplifiableArithExpr e
select e, "Should use '" + e.getRecommendation() + "' instead of '" + e.getCurrent() + "'"
