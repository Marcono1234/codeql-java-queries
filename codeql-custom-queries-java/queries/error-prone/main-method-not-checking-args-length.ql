/**
 * Finds `main` methods which do not check the length of the `args` argument.
 * This can make usage of the class from the command line more error-prone
 * because additional unused arguments are simply ignored (instead of informing
 * the user). And when a certain amount of arguments are required, but less
 * are provided, the user will only see a cryptic `ArrayIndexOutOfBoundsException`.
 */

import java
import semmle.code.java.dataflow.DataFlow

private predicate isArrayLengthChecked(Expr argsExpr) {
    exists(Expr sink |
        DataFlow::localFlow(DataFlow::exprNode(argsExpr), DataFlow::exprNode(sink))
    |
        // Args `length` field is read
        exists(FieldAccess f |
            f.getQualifier() = sink
            and f.getField() instanceof ArrayLengthField
        )
        // Args are cloned and clone length is checked
        or exists(MethodAccess c |
            c.getQualifier() = sink
            and c.getMethod() instanceof CloneMethod
            // Result of clone() is checked
            and isArrayLengthChecked(c)
        )
        // Or args are stored in field; maybe length is checked later
        or any(FieldWrite f).getRhs() = sink
        // Or args are passed to method; maybe length is checked there
        or any(MethodAccess c).getAnArgument() = sink
        // Or args are stored in array; maybe length is checked later
        or exists(AssignExpr a |
            a.getDest() instanceof ArrayAccess
            and a.getRhs() = sink
        )
        // Or new array containing args is created; maybe length is checked later
        or any(ArrayInit a).getAnInit() = sink
    )
}

from MainMethod m, Parameter argsParam
where
    m.fromSource()
    and argsParam = m.getParameter(0)
    // Ignore test classes
    and not m.getDeclaringType() instanceof TestClass
    // Either no access of `args`, or length is not checked
    and not isArrayLengthChecked(argsParam.getAnAccess())
select m, "Main method does not check $@ length", argsParam, argsParam.getName()
