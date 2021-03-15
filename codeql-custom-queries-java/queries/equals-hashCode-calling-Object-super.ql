/**
 * Finds classes which only extend Object, but call `super.equals`,
 * respectively `super.hashCode` in their `equals` / `hashCode` implementation.
 * This defeats the purpose of implementing own equality criteria, because
 * the implementation by Object only checks for identity.
 *
 * If the intention is to check `obj == this` by calling `Object.equals`,
 * then it is better to write that explicitly. Otherwise one might wonder
 * (without checking which parent classes a class has) why the `super.equals`
 * check is not at the beginning of the method and why the method does not
 * return fast if the result is `false`.
 */

import java

predicate delegatesToParent(Method m, MethodAccess superCall) {
    m.getBody().getNumStmt() = 1
    and exists (ReturnStmt returnStmt |
        m.getBody().getLastStmt() = returnStmt
        and returnStmt.getResult() = superCall
    )
}

from Method method, MethodAccess superCall
where
    // Verify that class has Object as its super class
    exists (TypeObject object | method.getDeclaringType().hasSupertype(object))
    and superCall.getQualifier() instanceof SuperAccess
    and superCall.getEnclosingCallable() = method
    and (
        (   
            method instanceof EqualsMethod
            and superCall.getMethod() instanceof EqualsMethod
        )
        or 
        (
            method instanceof HashCodeMethod
            and superCall.getMethod() instanceof HashCodeMethod
        )
    )
    // Ignore implementations which simply delegate to the parent
    // E.g. to change the method javadoc
    and not delegatesToParent(method, superCall)
select method, superCall
