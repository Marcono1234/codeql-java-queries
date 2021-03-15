/**
 * Finds mixed binary operators which are not enclosed by parentheses.
 * While precedence of arithmetic, boolean or bitwise operators on their
 * own might be obvious (e.g. `*` before `+`), their precedence when
 * combined with operators of other kinds might not be that obvious.
 * E.g.:
 * ```
 * boolean d = ...;
 *
 * // Is equivalent to: ((a << (2 + b)) < c) & d
 * if (a << 2 + b < c & d) {
 *     ...
 * }
 * ```
 * For better readability, the operands should be enclosed with parentheses.
 *
 * See also https://docs.oracle.com/javase/tutorial/java/nutsandbolts/operators.html
 */

import java

abstract class BinaryExprKind extends BinaryExpr {
    abstract predicate shouldBeParenthesized(BinaryExprKind op);
}

class ArithmeticKind extends BinaryExprKind {
    ArithmeticKind() {
        this instanceof AddExpr
        or this instanceof SubExpr
        or this instanceof MulExpr
        or this instanceof DivExpr
        or this instanceof RemExpr
    }
    
    override predicate shouldBeParenthesized(BinaryExprKind op) {
        // There are no operators with higher precedence which could be
        // confusing
        none()
    }
}

class ShiftKind extends BinaryExprKind {
    ShiftKind() {
        this instanceof LShiftExpr
        or this instanceof RShiftExpr
        or this instanceof URShiftExpr
    }
    
    override predicate shouldBeParenthesized(BinaryExprKind op) {
        not op instanceof ShiftKind
    }
}

class ComparisonKind extends BinaryExprKind {
    ComparisonKind() {
        this instanceof LTExpr
        or this instanceof LEExpr
        or this instanceof GTExpr
        or this instanceof GEExpr
    }
    
    override predicate shouldBeParenthesized(BinaryExprKind op) {
        op instanceof ShiftKind
    }
}

class EqualityTestKind extends EqualityTest, BinaryExprKind {
    override predicate shouldBeParenthesized(BinaryExprKind op) {
        op instanceof ShiftKind
        or op instanceof ComparisonKind
    }
}

class BitwiseKind extends BitwiseExpr, BinaryExprKind {
    // Could also consider EqualityTest operand when used for booleans,
    // but most of the times it is clear in which order the expressions are
    // evaluated
    override predicate shouldBeParenthesized(BinaryExprKind op) {
        op instanceof ArithmeticKind
        or op instanceof ShiftKind
        // XOR has higher precedence than OR, though knowledge about this might not
        // be that common
        or this instanceof OrBitwiseExpr and op instanceof XorBitwiseExpr
        // Boolean operands
        or op instanceof ComparisonKind
    }
}

class BooleanKind extends BinaryExprKind {
    BooleanKind() {
        this instanceof OrLogicalExpr
        or this instanceof AndLogicalExpr
    }
    
    // Could also consider EqualityTest operand when used for booleans,
    // but most of the times it is clear in which order the expressions are
    // evaluated
    override predicate shouldBeParenthesized(BinaryExprKind op) {
        // Bitwise for boolean operands
        op instanceof BitwiseKind
    }
}

from BinaryExprKind expr, BinaryExprKind operand
where
    operand = expr.getAnOperand()
    and not operand.isParenthesized()
    and expr.shouldBeParenthesized(operand)
select expr, operand
