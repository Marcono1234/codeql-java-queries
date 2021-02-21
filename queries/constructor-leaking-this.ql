/**
 * Finds constructors which leak a reference to the constructed object
 * (i.e. `this`). Doing so can cause incorrect behavior when the receiver
 * of the reference tries to access the object, but the constructor has
 * not assigned all fields yet.
 * Additionally leaking a reference to the constructed object can break
 * `final` field guarantees regarding the Java Memory Model, see
 * [JLS 15 §17.5](https://docs.oracle.com/javase/specs/jls/se15/html/jls-17.html#jls-17.5).
 *
 * Often it is saner to have the caller of the constructor store the
 * reference to the constructed object, or to introduce a static factory
 * method doing that.
 */

import java
import semmle.code.java.dataflow.DataFlow

private Expr getQualifier(Expr memberAccess) {
    result = memberAccess.(FieldAccess).getQualifier()
    or result = memberAccess.(MethodAccess).getQualifier()
}

private predicate isStaticMemberAccess(Expr e) {
    e.(FieldAccess).getField().isStatic()
    or e.(MethodAccess).getMethod().isStatic()
    or isStaticMemberAccess(getQualifier(e))
}

private predicate isParameterMemberAccess(Constructor c, Expr e) {
    DataFlow::localFlow(DataFlow::parameterNode(c.getAParameter()), DataFlow::exprNode(getQualifier*(e)))
}

private ThisAccess getThisStoredExternally(Constructor c, Expr leakingExpr) {
    // Leaks by calling external method
    (
        result = leakingExpr.(MethodAccess).getAnArgument()
        and (
            isStaticMemberAccess(leakingExpr)
            or isParameterMemberAccess(c, leakingExpr.(MethodAccess).getQualifier())
        )
    )
    // Leaks by assigning to external field
    or (
        result = leakingExpr.(FieldWrite).getRHS()
        and (
            isStaticMemberAccess(leakingExpr)
            or isParameterMemberAccess(c, leakingExpr.(FieldWrite).getQualifier())
        )
    )
    // Leaks by storing in external array
    or exists(AssignExpr assign, Expr arraySource | assign = leakingExpr |
        result = assign.getRhs()
        and assign.getDest().(ArrayAccess).getArray() = arraySource
        and (
            isStaticMemberAccess(arraySource)
            or isParameterMemberAccess(c, arraySource)
        )
    )
}

from Constructor c, Expr leakingExpr, ThisAccess thisAccess
where
    leakingExpr.getEnclosingCallable() = c
    and thisAccess.getEnclosingCallable() = c
    and thisAccess.isOwnInstanceAccess()
    and thisAccess = getThisStoredExternally(c, leakingExpr)
select leakingExpr, "Leaks `this` $@", thisAccess, "here"
