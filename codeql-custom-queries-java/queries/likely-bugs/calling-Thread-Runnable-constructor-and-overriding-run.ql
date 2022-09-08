/**
 * Finds calls to the `Thread` constructor from subclasses which provide a `Runnable` to
 * the constructor but also override `run()` without calling `super.run()`. This renders
 * the `Runnable` provided to the constructor useless because it will not be executed.
 * 
 * @kind problem
 */

import java

class RunMethod extends Method {
    RunMethod() {
        hasStringSignature("run()")
    }
}

from ConstructorCall threadConstructorCall, Constructor calledConstructor, Class c, RunMethod runMethod
where
    calledConstructor = threadConstructorCall.getConstructor()
    and calledConstructor.getDeclaringType().getASourceSupertype*().hasQualifiedName("java.lang", "Thread")
    and (
        c = threadConstructorCall.(SuperConstructorInvocationStmt).getEnclosingCallable().getDeclaringType()
        // Ignore implicit super(...) call for anonymous classes; for them the `null` arg check below does not work
        // Additionally anonymous classes are handled with ClassInstanceExpr below separately
        and not threadConstructorCall.getEnclosingCallable().getDeclaringType() instanceof AnonymousClass
        or
        c = threadConstructorCall.(ClassInstanceExpr).getAnonymousClass()
    )
    // And constructor with Runnable parameter is called
    and exists(int runnableIndex |
        calledConstructor.getParameterType(runnableIndex).(RefType).hasQualifiedName("java.lang", "Runnable")
        // But is not called with `null` as Runnable
        and not exists(Expr nullRunnableArg |
            nullRunnableArg = threadConstructorCall.getArgument(runnableIndex)
        |
            nullRunnableArg instanceof NullLiteral
            // Or cast which is used to select correct constructor overload
            or nullRunnableArg.(CastExpr).getExpr() instanceof NullLiteral
        )
    )
    // And overrides run() method
    and runMethod.getDeclaringType() = c
    // And does not have any method which calls super.run()
    and not exists(SuperMethodAccess superRunCall |
        superRunCall.getMethod() instanceof RunMethod
        and superRunCall.getEnclosingCallable().getDeclaringType() = c
    )
select threadConstructorCall, "Creates Thread with Runnable, but overrides run() method $@", runMethod, "here"
