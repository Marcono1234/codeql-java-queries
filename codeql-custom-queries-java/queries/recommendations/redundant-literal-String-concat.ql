/**
 * Finds String concatenation between a String literal and another literal. In most
 * cases such concatenation is redundant and the other literal can just be included
 * in the String literal for better readability. E.g.:
 * - `"value: " + 1` → `"value: 1"`
 * - `'{' + "text"` → `"{text"`
 * 
 * If the intention was to use the same value for the String and for something else,
 * it might be better to introduce a variable or field for this to make the
 * connection more obvious. E.g.:
 * ```java
 * // Uses a local variable to store the value
 * int maxLength = 10;
 * if (length > maxLength) {
 *     throw new IllegalArgumentException("Length is greater than " + maxLength);
 * }
 * ```
 * If the variable or field is (effectively) `final` the result of the String
 * concatenation will already be determined at compile time.
 */

import java
import lib.Literals

class PlusOrMinusExpr extends UnaryExpr {
    PlusOrMinusExpr() {
        this instanceof PlusExpr
        or this instanceof MinusExpr
    }
}

class StringifiableLiteral extends Literal {
    StringifiableLiteral() {
        // Ignore if literal cannot be easily included in String
        // E.g. `0xFFFF` would have to be written in decimal notation
        not (
            (this instanceof IntegerLiteral or this instanceof LongLiteral)
            // Binary, octal or hexadecimal notation, or containing underscore
            and this.getLiteral().regexpMatch(".*[xXbB_].*|^0.+")
        )
        // Hexadecimal notation, using exponent or containing underscore
        and not this.(FloatingPointLiteral_).getLiteral().regexpMatch(".*[xXeE_].*")
    }
}

class NumericLiteral extends Literal {
    NumericLiteral() {
        this instanceof IntegerLiteral
        or this instanceof LongLiteral
        or this instanceof FloatLiteral
        or this instanceof DoubleLiteral
    }
}

class StringifiableExpression extends Expr {
    StringifiableExpression() {
        this instanceof StringifiableLiteral
        // Only consider numeric literals to ignore plus or minus in front of
        // char literal
        or this.(PlusOrMinusExpr).getExpr().(NumericLiteral) instanceof StringifiableLiteral
    }
}

from AddExpr concatExpr, Expr opA, Expr opB
where
    concatExpr.getType() instanceof TypeString
    and opA = concatExpr.getAnOperand()
    and opB = concatExpr.getAnOperand()
    and opA != opB
    and (
        /*
         * Either a String literal, or the result of a String concatenation
         * where the right operand is a String literal, e.g. `1 + "a" + 2`
         * (here `1 + "a"` would match).
         */
        opA instanceof StringLiteral
        or (
            opA = concatExpr.getLeftOperand()
            and opA.(AddExpr).getRightOperand() instanceof StringLiteral
        )
    )
    and opB instanceof StringifiableExpression
    // If both are String literals, or other is char literal make sure they are in
    // the same line, otherwise it might be a String literal wrapped to the next line
    // TODO: Concat between String literals cannot be detected, see https://github.com/github/codeql/issues/5469
    and (
        (opB instanceof StringLiteral or opB instanceof CharacterLiteral)
        implies opA.getLocation().getEndLine() = opB.getLocation().getStartLine())
select concatExpr, "Redundant String concatenation"
