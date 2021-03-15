/**
 * Finds calls to `initCause(Throwable)` of `Throwable` or a subtype which
 * appears to have a constructor with a parameter for a cause exception which
 * could be used instead.
 * E.g.:
 * ```
 * try {
 *     ...
 * }
 * catch (IOException cause) {
 *     // Should use UncheckedIOException(String, IOException)
 *     UncheckedIOException e = new UncheckedIOException("Action failed");
 *     e.initCause(cause);
 *     throw e;
 * }
 * ```
 * To improve readability the alternative constructor with cause parameter
 * should be used instead of manually setting the cause through `initCause`.
 */

import java
import semmle.code.java.dataflow.DataFlow

class InitCauseMethod extends Method {
    InitCauseMethod() {
        getDeclaringType().getASourceSupertype*() instanceof TypeThrowable
        and hasStringSignature("initCause(Throwable)")
    }
}

class InitCauseCall extends MethodAccess {
    InitCauseCall() {
        getMethod() instanceof InitCauseMethod
    }
    
    RefType getCauseType() {
        result = getArgument(0).getType()
    }
}

Constructor getAlternativeConstructor(Constructor c, RefType causeType) {
    result.getDeclaringType() = c.getDeclaringType()
    and result.getNumberOfParameters() = c.getNumberOfParameters() + 1
    // And has additional cause argument; verify that cause can actually be used as
    // constructor argument, some constructors only allow certain subtypes of Throwable
    and result.getParameterType(result.getNumberOfParameters() - 1) = causeType.getASourceSupertype*()
    // And all other parameters are the same
    and forall(int paramIndex | paramIndex = [0 .. c.getNumberOfParameters() - 1] |
        c.getParameterType(paramIndex) = result.getParameterType(paramIndex)
    )
}

from ClassInstanceExpr newException, InitCauseCall initCauseCall, Constructor alternative
where
    DataFlow::localFlow(DataFlow::exprNode(newException), DataFlow::exprNode(initCauseCall.getQualifier()))
    and alternative = getAlternativeConstructor(newException.getConstructor(), initCauseCall.getCauseType())
select initCauseCall, "Can be removed and instead $@ this constructor could be called: $@",
    newException, "here", alternative, alternative.getStringSignature()
