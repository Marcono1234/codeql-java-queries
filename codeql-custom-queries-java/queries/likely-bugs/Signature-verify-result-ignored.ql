/**
 * Finds usage of the `verify` method of `java.security.Signature` where the result
 * of the call is ignored. This renders the signature verification ineffective.
 */

 // Similar to CodeQL's java/ignored-hostname-verification

import java
import semmle.code.java.dataflow.TaintTracking

import lib.Expressions

// TODO: Maybe improve reporting usage as method reference expression where result is ignored

from MethodAccess verifyCall, Method verifyMethod
where
    verifyCall.getMethod() = verifyMethod
    and verifyMethod.getDeclaringType().getASourceSupertype*().hasQualifiedName("java.security", "Signature")
    and verifyMethod.hasName("verify")
    // And result is ignored
    and (
        verifyCall instanceof StmtExpr
        or not exists(Expr sink |
            TaintTracking::localExprTaint(verifyCall, sink)
        |
            any(ReturnStmt s).getResult() = sink
            or any(ConditionNode n).getCondition() = sink
            or any(Call c).getAnArgument() = sink
        )
    )
    and not verifyCall.getEnclosingCallable().getDeclaringType() instanceof TestClass
select verifyCall, "Signature verification result is ignored"
