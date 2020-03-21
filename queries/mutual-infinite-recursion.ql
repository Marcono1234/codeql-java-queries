/**
 * Finds cases of (potential) infinite recursion where a method calls
 * the same method on one of its args with the same arguments, except
 * `this` instead of the argument on which it calls the method, e.g.:
 * ```
 * public boolean equals(Object obj) {
 *     return obj.equals(this);
 * }
 * ```
 * This can lead to infinite recursing when `this` is passed as argument.
 */

import java
import semmle.code.java.dataflow.DataFlow

predicate flowThisToArg(MethodAccess call, int argIndex) {
    exists (DataFlow::Node src |
        DataFlow::localFlow(src, DataFlow::exprNode(call.getArgument(argIndex)))
        and src.asExpr() instanceof ThisAccess
    )
}

predicate callsWithSameArgs(Method m, MethodAccess call, int thisIndex) {
    forall (int paramIndex, Parameter p | p = m.getParameter(paramIndex) |
        DataFlow::localFlow(DataFlow::parameterNode(p), DataFlow::exprNode(call.getArgument(paramIndex)))
        or (
            thisIndex = paramIndex
            and flowThisToArg(call, paramIndex)
        )
    )
    // Make sure `this` is only used as one arg
    and not exists(int otherArgIndex | otherArgIndex != thisIndex |
        flowThisToArg(call, otherArgIndex)
    )
    and call.getQualifier().(VarAccess).getVariable() = m.getParameter(thisIndex)
}

from MethodAccess call, Method method, int thisIndex
where
    not method.isStatic()
    // Check if method is calling itself or parent implementation
    and (method = call.getCallee() or method.overrides(call.getCallee()))
    // Check if all arguments to the call are the parameters of this method
    and callsWithSameArgs(method, call, thisIndex)
    // Check that argument is not re-assigned a value
    and not exists (LValue write | write.getVariable() = method.getAParameter())
    // Check that if argument is array, none of its elements are re-assigned
    and not exists (ArrayAccess paramArrayAccess | 
        paramArrayAccess.getArray().(RValue).getVariable() = method.getAParameter()
        and exists (Assignment assign | assign.getDest() = paramArrayAccess)
    )
select call
