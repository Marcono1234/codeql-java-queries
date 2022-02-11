/**
 * Finds permission checks which call `SecurityManager` methods or create
 * `Permission` objects with a value obtained from a method which can be
 * overridden, or a field whose value can be replaced.
 * Using such methods or fields for permission checks might allow an adversary
 * to replace the value between the check and usage, allowing them to bypass
 * the permission check.
 */

/*
 * Currently does not account for storing value in local variable
 * and then using its value for check and action guarded by the check (which
 * would be safe); however, it is difficult to detect this, especially because
 * it is not clear which dangerous action the security check is guarding.
 * Merely looking for sinks accepting the value might cause false negatives
 * when that sink is only some kind of logging method or similar.
 */

import java
import semmle.code.java.dataflow.DataFlow

import lib.Types

class TypeSecurityManager extends Class {
    TypeSecurityManager() {
        hasQualifiedName("java.lang", "SecurityManager")
    }
}

class SecurityManagerCheckMethod extends Method {
    SecurityManagerCheckMethod() {
        getDeclaringType().getASourceSupertype*() instanceof TypeSecurityManager
        and getName().matches("check%")
    }
    
    int getACheckedParamIndex() {
        result = [0 .. getNumberOfParameters() - 1]
        // Ignore Object context parameters
        and not (
            result = getNumberOfParameters() - 1
            and getParameterType(result) instanceof TypeObject
        )
        // Ignore Permission parameters (creation of Permission objects is checked separately)
        and not getParameterType(result).(RefType).getASourceSupertype*() instanceof TypePermission
    }
}

class TypePermission extends Class {
    TypePermission() {
        hasQualifiedName("java.security", "Permission")
    }
}

// TODO: Move all this publicly accessible logic to common library
//       Note that this is different from the predicates provided by
//       CodeQL which check if overriding method is possible at all,
//       including from same package or class

private predicate isPubliclyVisible(RefType t) {
    (t.isProtected() or t.isPublic())
    // Enclosing type, if any, must be publicly visible as well
    // Top level class cannot be `protected` so don't have to check for that case
    and (exists(t.getEnclosingType()) implies isPubliclyVisible(t.getEnclosingType()))
}

private predicate canBeAccessed(Member m) {
    exists(RefType t, Member memberToCheck |
        // Check declaring type and subtypes; declaring type might not be accessible,
        // but maybe one of its subtypes is
        t.getASourceSupertype*() = m.getDeclaringType()
        and (
            memberToCheck = m
            // Or there is an override which can be accessed
            or exists(Method override |
                memberToCheck = override
            |
                override.getDeclaringType() = t.getASourceSupertype*()
                and override.getSourceDeclaration().overridesOrInstantiates*(m)
                and not override.isFinal()
            )
        )
    |
        isPubliclyVisible(t)
        and (
            memberToCheck.isPublic()
            // If `protected` declaring must be subclassable to access member
            or memberToCheck.isProtected() and isPubliclySubclassable(t)
        )
        // And when checking subclasses of declaring type, make sure they do not
        // override method and make it `final`
        and not exists(Method override |
            override.isFinal()
            and override.getDeclaringType() = t.getASourceSupertype*()
            and override.getSourceDeclaration().overridesOrInstantiates*(memberToCheck)
        )
    )
}

/**
 * Holds if the field read occurs on a field whose value can be
 * replaced.
 */
private predicate isUnsafeFieldRead(FieldRead read) {
    exists(Field f | f = read.getField() |
        // `final` field read is safe because its value cannot be changed
        not f.isFinal()
        and canBeAccessed(f)
    )
}

/**
 * Holds if the call is to a method which can be overridden and therefore
 * allows replacing the returned value.
 */
private predicate isUnsafeMethodCall(MethodAccess call) {
    exists(Method m | m = call.getMethod() |
        // `final` method call is safe because it cannot be overridden
        not m.isFinal()
        and canBeAccessed(m)
        // Declaring type must be subclassable to override method
        and isPubliclySubclassable(m.getDeclaringType())
    )
}

from Expr checkedActionRetrieval, Expr checkedActionSink
where
    (
        // Creation of Permission object
        exists(ClassInstanceExpr newExpr |
            newExpr.getConstructedType().getASourceSupertype*() instanceof TypePermission
            and checkedActionSink = newExpr.getAnArgument()
        )
        // Or `SecurityManager.check...()` method call
        or exists(MethodAccess checkCall, SecurityManagerCheckMethod checkMethod |
            checkCall.getMethod() = checkMethod
            and checkedActionSink = checkCall.getArgument(checkMethod.getACheckedParamIndex())
        )
    )
    // Ignore test classes
    and not checkedActionSink.getEnclosingCallable().getDeclaringType().getEnclosingType*() instanceof TestClass
    and DataFlow::localFlow(DataFlow::exprNode(checkedActionRetrieval), DataFlow::exprNode(checkedActionSink))
    // Only consider field or method access where user could replace value in the meantime
    and (
        isUnsafeFieldRead(checkedActionRetrieval)
        or isUnsafeMethodCall(checkedActionRetrieval)
    )
select checkedActionRetrieval, "Obtains value which might be replaced by user and uses it for SecurityManager check $@", checkedActionSink, "here"
