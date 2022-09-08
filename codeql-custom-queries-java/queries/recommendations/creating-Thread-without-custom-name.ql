/**
 * Finds code which creates `Thread` instances without specifying a custom name, neither as
 * constructor argument nor by calling `setName`. Specifying a custom name can make debugging
 * and performance monitoring easier, otherwise a generic name is chosen which makes it more
 * difficult to identify the thread.
 * 
 * @kind problem
 */

import java
import semmle.code.java.dataflow.DataFlow

class TypeThread extends Class {
    TypeThread() {
        hasQualifiedName("java.lang", "Thread")
    }
}

class SetNameCall extends MethodAccess {
    SetNameCall() {
        exists(Method m | m = getMethod() |
            m.getDeclaringType().getASourceSupertype*() instanceof TypeThread
            and m.hasStringSignature("setName(String)")
        )
    }
}

from ConstructorCall newThread
where
    // Don't consider subtypes to avoid false positives
    newThread.getConstructedType() instanceof TypeThread
    and not exists(Expr nameArg |
        nameArg.getType() instanceof TypeString
        and nameArg = newThread.getAnArgument()
    )
    and (
        newThread instanceof ClassInstanceExpr
        and not exists(SetNameCall setNameCall |
            DataFlow::localExprFlow(newThread, setNameCall.getQualifier())
        )
        or
        newThread instanceof SuperConstructorInvocationStmt
        and not exists(SetNameCall setNameCall |
            setNameCall.getEnclosingCallable().getDeclaringType() = newThread.getEnclosingCallable().getDeclaringType()
            and setNameCall.isOwnMethodAccess()
        )
        // Ignore ThisConstructorInvocationStmt because called constructor might call super constructor with name
    )
    and not newThread.getEnclosingCallable().getDeclaringType() instanceof TestClass
select newThread, "Creates Thread without custom name"
