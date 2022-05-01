/**
 * Finds calls to a method with `java.lang.Void` as return type, but whose
 * result is used in some way. `Void` cannot be instantiated so the only
 * possible value is `null`. The type is often used to indicate that the
 * result does not matter. Therefore code which uses the result in some
 * way might indicate a bug.
 */

import java
import lib.Expressions

class OwnConstructorInvocationStmt extends ConstructorCall {
    Constructor c;

    OwnConstructorInvocationStmt() {
        c = this.(ThisConstructorInvocationStmt).getConstructor()
        or c = this.(SuperConstructorInvocationStmt).getConstructor()
    }

    override
    Constructor getConstructor() {
        result = c
    }
}

from MethodAccess call
where
    // For generic methods this matches the actual type argument of the receiver
    call.getMethod().getReturnType().(RefType).hasQualifiedName("java.lang", "Void")
    // And result is not discarded
    and not call instanceof ValueDiscardingExpr
    // Ignore if result is returned (only applies to methods with Object or Void as return
    // type), e.g. when call delegates to other method
    and not any(ReturnStmt r).getResult() = call
    // Ignore test classes which might verify that value is null, e.g. using `assertNull(...)`
    and not call.getEnclosingCallable().getDeclaringType() instanceof TestClass
    // Ignore if call is argument to own constructor call; `this(...)` and `super(...)`
    // have to appear as first statement, therefore some projects (mainly the OpenJDK)
    // use a Void method for performing permission checks and then call a delegate
    // constructor with a dummy Void parameter
    and not any(OwnConstructorInvocationStmt c).getAnArgument() = call
select call, "Uses Void result"
