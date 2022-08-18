/**
 * Finds usages of StringBuffer where StringBuilder could be used instead.
 * StringBuffer has all methods synchronized which can incur unnecessary
 * overhead if it is not used by multiple threads.
 */

import java
import semmle.code.java.dataflow.DataFlow

import lib.Expressions

from ClassInstanceExpr newExpr
where
    newExpr.getConstructedType() instanceof TypeStringBuffer
    // No reference in other callable, e.g. method within anonymous class
    and not exists (Expr expr |
        expr.getEnclosingCallable() != newExpr.getEnclosingCallable()
        and DataFlow::localFlow(DataFlow::exprNode(newExpr), DataFlow::exprNode(expr))
    )
    // No reference becomes available to other method
    and not isLeaked(newExpr)
select newExpr
