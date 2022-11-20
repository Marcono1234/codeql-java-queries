/**
 * Finds calls to validation methods where the argument to validate and the error message
 * are switched. Therefore the error message is validated instead of the other argument.
 * 
 * Based on SpotBugs [`DMI_ARGUMENTS_WRONG_ORDER`](https://spotbugs.readthedocs.io/en/latest/bugDescriptions.html#dmi-reversed-method-arguments-dmi-arguments-wrong-order).
 *
 * @kind problem
 */

import java

predicate isMessage(Expr e) {
    e instanceof StringLiteral
    // Or is part of string concatenation
    or isMessage(e.(AddExpr).getAnOperand())
}

private Type getErasure(Type t) {
    result = t.getErasure()
    // Workaround for https://github.com/github/codeql/issues/11264
    and ((t instanceof ClassOrInterface and not t instanceof TypeObject) implies not result instanceof TypeObject)
}

from MethodAccess call, Method method, int argIndex, int messageIndex
where
    method = call.getMethod()
    // Validation methods are often static
    and method.isStatic()
    // Validation methods usually either have `void` as return type or return the provided argument
    and exists(Type returnType | returnType = method.getReturnType() |
        returnType instanceof VoidType
        or returnType = method.getParameterType(argIndex)
    )
    // One message parameter and one argument parameter
    and method.getNumberOfParameters() = 2
    // Argument type is Object or a type variable without upper bounds
    and getErasure(method.getParameterType(argIndex)) instanceof TypeObject
    // Message is provided as argument
    and isMessage(call.getArgument(argIndex))
    and method.getParameterType(messageIndex) instanceof TypeString
    and not call.getArgument(messageIndex).(CompileTimeConstantExpr).getType() instanceof TypeString
select call, "Argument to validate and message are switched"
