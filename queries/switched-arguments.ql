/**
 * Finds cases of switched arguments based on argument and parameter names.
 */

import java

// TODO: Possibly pretty inefficient currently

// TODO: This does not cover primitives conversion and might be wrong for generics
predicate isAssignable(Type paramType, Type argType) {
    paramType = argType
    or exists (RefType ancestor | ancestor = argType.(RefType).getAnAncestor() | paramType.(RefType) = ancestor)
}

predicate isMatchingArg(MethodAccess call, Variable var) {
    exists(int paramIndex, Parameter p | p = call.getMethod().getParameter(paramIndex) |
        call.getArgument(paramIndex).(RValue).getVariable() = var
        and p.getName() = var.getName()
        and isAssignable(p.getType(), var.getType())
    )
}

from MethodAccess call, Method method, int paramIndex, Parameter otherParam, RValue arg, Variable var
where
    call.getMethod() = method
    and arg = call.getArgument(paramIndex)
    // Find a parameter with the same name as the argument,
    // but at a different index
    and otherParam = method.getAParameter()
    and otherParam != method.getParameter(paramIndex)
    and var = arg.getVariable()
    and otherParam.getName() = var.getName()
    and isAssignable(otherParam.getType(), var.getType())
    // Var might be used as multiple args, verify that it is not matching
    and not isMatchingArg(call, var)
select arg, otherParam
