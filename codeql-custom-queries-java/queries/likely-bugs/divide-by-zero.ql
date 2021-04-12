/**
 * Finds expressions which calculate the perform a division or calculate the
 * remainder with a divisor of 0.
 * For integer types this will result in a runtime exception, for floating point
 * types the result will be one of the non-finite values `Infinity` or `NaN`.
 */

import java
import semmle.code.java.controlflow.Guards

class ZeroExpr extends Expr {
    ZeroExpr() {
        this.(CompileTimeConstantExpr).getIntValue() = 0
        or this.(LongLiteral).getValue() = "0"
        or this.(FloatingPointLiteral).getValue() = "0.0"
        or this.(DoubleLiteral).getValue() = "0.0"
        // Or read of final variable with 0 as value
        or exists(Variable v |
            v.isFinal()
            and v.getAnAssignedValue() instanceof ZeroExpr
            and this = v.getAnAccess()
        )
        // Or cast of 0
        or this.(CastExpr).getExpr() instanceof ZeroExpr
    }
}

private ControlFlowNode getLValueControlFlowNode(LValue lValue) {
    // For LValue control flow node would be var access, which has no control flow
    // for AssignExpr and flow in wrong order for AssignOp. Therefore instead use
    // the node of the parent (assignment), see also https://github.com/github/codeql/issues/5652
    result = lValue.getParent().(Expr).getControlFlowNode()
}

from Expr divExpr, Expr effectivelyZeroExpr, string message, Expr reportedZeroExpr, string reportedZeroExprText
where
    (
        (divExpr instanceof DivExpr or divExpr instanceof RemExpr)
        and divExpr.(BinaryExpr).getRightOperand() = effectivelyZeroExpr
        or
        (divExpr instanceof AssignDivExpr or divExpr instanceof AssignRemExpr)
        and divExpr.(AssignOp).getRhs() = effectivelyZeroExpr
    )
    and (
        // Expression is 0
        (
            effectivelyZeroExpr instanceof ZeroExpr
            and reportedZeroExpr = effectivelyZeroExpr
            and reportedZeroExprText = "this"
            and message = "$@ expression which is 0"
        )
        // Or there is a guard which guarantees that the expression is 0
        or exists(Variable var, ConditionBlock cond, EqualityTest eqTest, ZeroExpr zeroExpr, VarAccess varAccess |
            cond.getCondition() = eqTest
            and eqTest.getAnOperand() = zeroExpr
            and eqTest.getAnOperand() = varAccess
            and varAccess = var.getAnAccess()
            and varAccess != zeroExpr
            and effectivelyZeroExpr = var.getAnAccess()
            // 0-check controls divide expression
            and cond.controls(divExpr.getBasicBlock().getBasicBlock*(), eqTest.polarity())
            // And there is no variable write before divide expression
            and not exists(LValue varWrite, ControlFlowNode node |
                varWrite.getVariable() = var
                and node = getLValueControlFlowNode(varWrite)
                and node.getAPredecessor+() = eqTest
                and node.getASuccessor+() = effectivelyZeroExpr
            )
            and reportedZeroExpr = eqTest
            and reportedZeroExprText = "this"
            and message = "variable which is 0 due to $@ check"
        )
        // Or local variable is assigned 0 and not reassigned
        or exists(LocalScopeVariable var, VariableAssign assign |
            effectivelyZeroExpr = var.getAnAccess()
            and assign.getDestVar() = var
            and assign.getSource() instanceof ZeroExpr
            // Ignore final variables, they are already covered by ZeroExpr
            and not var.isFinal()
            and assign.getControlFlowNode().getASuccessor+() = effectivelyZeroExpr
            // And there is no reassign
            and not exists(LValue varWrite, ControlFlowNode node |
                varWrite.getVariable() = var
                and node = getLValueControlFlowNode(varWrite)
                and node.getAPredecessor+() = assign
                and node.getASuccessor+() = effectivelyZeroExpr
            )
            and reportedZeroExpr = assign
            and reportedZeroExprText = "here"
            and message = "variable which is assigned 0 $@"
        )
    )
select divExpr, "Divides by " + message, reportedZeroExpr, reportedZeroExprText
