/**
 * Finds cases of switched arguments based on argument and parameter names.
 */

import java
import semmle.code.java.dataflow.DataFlow

// TODO: This does not cover primitives conversion and might be wrong for generics
predicate isAssignable(Type paramType, Type argType) {
    paramType = argType
    or exists (RefType ancestor | ancestor = argType.(RefType).getAnAncestor() | paramType.(RefType) = ancestor)
}

predicate flowVarToArg(RValue varReadExpr, Expr arg) {
    DataFlow::localFlow(DataFlow::exprNode(varReadExpr), DataFlow::exprNode(arg))
}

predicate isMatchingArg(MethodAccess call, Variable var) {
    exists(int paramIndex, Parameter p, RValue varReadExpr | p = call.getMethod().getParameter(paramIndex) |
        varReadExpr.getVariable() = var
        and p.getName() = var.getName()
        and isAssignable(p.getType(), var.getType())
        and flowVarToArg(varReadExpr, call.getArgument(paramIndex))
    )
}

from MethodAccess call, Method method, int paramIndex, Parameter otherParam, Variable var, RValue varReadExpr
where
    call.getMethod() = method
    and flowVarToArg(varReadExpr, call.getArgument(paramIndex))
    // Find a parameter with the same name as the argument,
    // but at a different index
    and otherParam = method.getAParameter()
    and otherParam != method.getParameter(paramIndex)
    and var = varReadExpr.getVariable()
    and otherParam.getName() = var.getName()
    and isAssignable(otherParam.getType(), var.getType())
    // Var might be used as multiple args, verify that it is not matching
    and not isMatchingArg(call, var)
select call, varReadExpr, otherParam
