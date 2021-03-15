/**
 * Finds usages of StringBuffer where StringBuilder could be used instead.
 * StringBuffer has all methods synchronized which can incur unnecessary
 * overhead if it is not used by multiple threads.
 */

import java
import semmle.code.java.dataflow.DataFlow

/**
 * Expression where a reference might become accessible to other
 * methods.
 */
class LeakingExpr extends Expr {
    LeakingExpr() {
        exists (ReturnStmt returnStmt | this = returnStmt.getResult())
        or exists (Call call | this = call.getAnArgument())
        or exists (LValue write |
            write.getVariable() instanceof Field
            and this = write.getRHS()
        )
        or exists (Assignment assignment |
            assignment.getDest() instanceof ArrayAccess
            and this = assignment.getSource()
        )
    }
}

from ClassInstanceExpr newExpr
where
    newExpr.getConstructedType() instanceof TypeStringBuffer
    // No reference in other callable, e.g. method within anonymous class
    and not exists (Expr expr |
        expr.getEnclosingCallable() != newExpr.getEnclosingCallable()
        and DataFlow::localFlow(DataFlow::exprNode(newExpr), DataFlow::exprNode(expr))
    )
    // No reference becomes available to other method
    and not exists (LeakingExpr expr |
        DataFlow::localFlow(DataFlow::exprNode(newExpr), DataFlow::exprNode(expr))
    )
select newExpr
