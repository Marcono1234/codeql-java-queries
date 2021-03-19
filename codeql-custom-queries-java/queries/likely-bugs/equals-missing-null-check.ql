/**
 * Finds implementations of `equals(Object)` which do not check if the
 * parameter is `null`, resulting in `NullPointerException`s. This violates
 * the contract of `equals`.
 */

import java
import semmle.code.java.dataflow.DataFlow
import lib.Expressions

class NpeExpr extends Expr {
    NpeExpr() {
        exists(MethodAccess call | this = call.getQualifier())
        or exists(CastExpr castExpr | this = castExpr.getExpr())
    }
}

class NullCheckExpr extends Expr {
    NullCheckExpr() {
        exists (InstanceOfExpr expr | this = expr.getExpr())
        or exists (EqualityTest eqTest |
            this = eqTest.getAnOperand()
            and eqTest.getAnOperand() instanceof NullLiteral
        )
        // Assume that methods which are called with the argument
        // check that it is non-null, e.g. `super.equals`
        or exists (MethodAccess checkCall |
            this = checkCall.getAnArgument()
            // Verify that result of method is actually used
            and not checkCall instanceof StmtExpr
        )
    }
}

from Method method, Parameter objParam, NpeExpr npeExpr
where
    method.hasStringSignature("equals(Object)")
    and objParam = method.getParameter(0)
    // Check that parameter is used in place where it could cause
    // a NullPointerException
    and DataFlow::localFlow(DataFlow::parameterNode(objParam), DataFlow::exprNode(npeExpr))
    // Verify that parameter is not checked to be non-null before
    // being used in expression causing NullPointerException
    and not exists(NullCheckExpr nullCheckExpr | DataFlow::localExprFlow(nullCheckExpr, npeExpr))
select method, npeExpr
