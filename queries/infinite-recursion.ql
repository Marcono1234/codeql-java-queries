/**
 * Finds cases of (potential) infinite recursion within the same method.
 */

import java
import semmle.code.java.dataflow.DataFlow

predicate callsWithSameArgs(Method m, MethodAccess call) {
    forall (int paramIndex, Parameter p | p = m.getParameter(paramIndex) |
        DataFlow::localFlow(DataFlow::parameterNode(p), DataFlow::exprNode(call.getArgument(paramIndex)))
    )
}

from MethodAccess call, Method method
where
    call.getMethod() = method
    // Check if this method is calling itself
    and call.getCallee() = call.getCaller()
    // Check if either the instance is calling its own method, or if the method is static
    and (call.isOwnMethodAccess() or method.isStatic())
    // Check if all arguments to the call are the parameters of this method
    and callsWithSameArgs(method, call)
    // Check that argument is not re-assigned a value
    and not exists (LValue write | write.getVariable() = method.getAParameter())
    // Check that if argument is array, none of its elements are re-assigned
    and not exists (ArrayAccess paramArrayAccess | 
        paramArrayAccess.getArray().(RValue).getVariable() = method.getAParameter()
        and exists (Assignment assign | assign.getDest() = paramArrayAccess)
    )
select call
