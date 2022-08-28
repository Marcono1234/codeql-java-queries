/**
 * Finds code which first loads a class by name, e.g. with `Class.forName`, then creates an instance
 * using `newInstance` and finally casts the result to the desired type. Often the cast can be avoided
 * by calling `asSubclass` on the loaded class to make sure it has the correct type. This also has
 * the advantage that, in case the class name can be influenced by an adversary, they cannot create
 * instances of arbitrary classes but are restriced to subclasses of a certain class.
 * 
 * For example:
 * ```java
 * Provider provider = (Provider) Class.forName(providerName).newInstance();
 * ```
 * should be replaced with:
 * ```java
 * Provider provider = Class.forName(providerName).asSubclass(Provider.class).newInstance();
 * ```
 * 
 * @kind problem
 */

import java
import semmle.code.java.Reflection
import semmle.code.java.dataflow.DataFlow

// TODO: Could maybe replace this with CodeQL's ReflectiveClassIdentifierMethodAccess (but does not cover MethodHandles$Lookup)
class ClassLoadingCall extends MethodAccess {
    ClassLoadingCall() {
        exists(Method m | m = getMethod() |
            m.hasName("forName")
            and m.getDeclaringType() instanceof TypeClass
            or
            m.hasName("loadClass")
            and m.getDeclaringType().getASourceSupertype*().hasQualifiedName("java.lang", "ClassLoader")
            or
            m.hasName("findClass")
            and m.getDeclaringType().getSourceDeclaration().hasQualifiedName("java.lang.invoke", "MethodHandles$Lookup")
        )
    }
}

// Note: Does not check for isAssignableFrom calls verifying class; often code manually throws exception
// then, so could probably be replaced with asSubclass as well

from ClassLoadingCall classLoadingCall, NewInstance newInstanceCall, CastExpr castExpr
where
    (
        // Calls Class.newInstance
        DataFlow::localExprFlow(classLoadingCall, newInstanceCall.getQualifier())
        // Or retrieves constructor and calls Constructor.newInstance
        or exists(ReflectiveConstructorsAccess constructorAccess |
            DataFlow::localExprFlow(classLoadingCall, constructorAccess.getQualifier())
            and DataFlow::localExprFlow(constructorAccess, newInstanceCall.getQualifier())
        )
    )
    and DataFlow::localExprFlow(newInstanceCall, castExpr.getExpr())
    // Ignore if code allows to load multiple different types (2 or more instanceof checks each guarding the cast)
    and not count(InstanceOfExpr instanceOfExpr |
        strictlyDominates(instanceOfExpr.getControlFlowNode(), castExpr.getControlFlowNode())
        and DataFlow::localExprFlow(newInstanceCall, instanceOfExpr.getExpr())
    ) >= 2
    // Ignore type variable without upper bound
    /*
     * Note: For type variable with bound, or for parameterized type the asSubclass call does
     * not allow avoiding the cast expression, but it still makes the code more secure if the
     * class name can be influenced by an adversary
     */
    and not castExpr.getType().(TypeVariable).getErasure() instanceof TypeObject
select classLoadingCall, "Should add `asSubclass(" + castExpr.getType().getErasure() + ".class)` to avoid $@", castExpr, "this cast"
