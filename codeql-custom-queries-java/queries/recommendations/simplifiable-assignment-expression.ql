/**
 * Finds assignment expressions which can be simplified by replacing them
 * with a compound assignment expression or with a unary increment or
 * decrement expression.
 * E.g.:
 * ```
 * // Could be replaced with `s += "suffix"`
 * s = s + "suffix";
 * ```
 */

import java
import lib.VarAccess

private predicate isCommutative(BinaryExpr e) {
    e instanceof AddExpr
    // String concatenation is not commutative
    and not e.(AddExpr).getType() instanceof TypeString
    or e instanceof AndBitwiseExpr
    or e instanceof EqualityTest
    or e instanceof MulExpr
    or e instanceof OrBitwiseExpr
    or e instanceof XorBitwiseExpr
}

/**
 * Gets the binary expression which is part of the `assignExpr` which can
 * be simplified, and binds `otherOperand` to the operand of the result
 * binary expression which remains after simplification.
 */
private BinaryExpr getSimplifiableAssignOperation(AssignExpr assignExpr, Expr otherOperand) {
    exists(Expr assignDestExpr, Expr updateOperandExpr |
        assignExpr.getDest() = assignDestExpr
        and assignExpr.getRhs() = result
        and otherOperand = result.getAnOperand()
        and exists(Expr assignDest, Expr varReadOperand |
            assignDest = assignExpr.getDest()
            and (
                if isCommutative(result) then varReadOperand = result.getAnOperand()
                // If not commutative only allow var read as left operand
                else varReadOperand = result.getLeftOperand()
            )
            // Don't select the same operand
            and varReadOperand != otherOperand
        |
            varReadOperand = updateOperandExpr
        )
        // Verify that both access same variable; ignore something like `var = other.var + ...`
        and accessSameVarOfSameOwner(assignDestExpr, updateOperandExpr)
    )
}

private predicate hasValue1(Literal literal) {
    literal.(IntegerLiteral).getIntValue() = 1
    or literal.(LongLiteral).getValue().toInt() = 1
    or literal.(FloatingPointLiteral).getValue().toFloat() = 1
    or literal.(DoubleLiteral).getValue().toFloat() = 1
}

private string getUnaryIncrementOrDecrementMessage(AssignExpr assignExpr, BinaryExpr binaryExpr, Literal literal) {
    hasValue1(literal)
    and binaryExpr.getType() instanceof NumericType
    and exists(string operator |
        binaryExpr instanceof AddExpr and operator = "increment ++"
        or binaryExpr instanceof SubExpr and operator = "decrement --"
    |
        // If result of assignment is used (e.g. `doSomething(a = a + 1)`), then must use pre unary
        if assignExpr.getParent() instanceof Expr then result = "pre " + operator
        else result = "post " + operator
    )
}

private string getCompoundAssignOp(string op) {
    op = ["+", "-", "*", "/", "%", "&", "^", "|", "<<", ">>", ">>>"]
    and result = op + "="
}

from AssignExpr assignExpr, BinaryExpr binaryExpr, Expr otherOperand, string alternative
where
    binaryExpr = getSimplifiableAssignOperation(assignExpr, otherOperand)
    and(
        // Use `if-else` to prevent duplicate message for unary increment / decrement
        if exists(getUnaryIncrementOrDecrementMessage(assignExpr, binaryExpr, otherOperand)) then (
            alternative = getUnaryIncrementOrDecrementMessage(assignExpr, binaryExpr, otherOperand)
        ) else (
            // Get compound op; some operators (&& and ||) do not have one
            // Use getOp().trim() because it had leading and trailing spaces
            alternative = getCompoundAssignOp(binaryExpr.getOp().trim())
        )
    )
select assignExpr, "Should use " + alternative
