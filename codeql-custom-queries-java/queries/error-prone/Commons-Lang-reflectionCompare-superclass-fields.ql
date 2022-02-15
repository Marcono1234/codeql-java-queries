/**
 * Finds usage of Apache Commons Lang's `CompareToBuilder.reflectionCompare` with an argument
 * whose superclass might not have been intended for reflective comparison. Such usage is
 * error-prone because the structure of the superclass, or one of its superclasses, might be
 * changed without considering the effects on the class using `reflectionCompare`.
 * 
 * In general care should be taken when using `reflectionCompare` because it depends on the
 * element order of `Class.getDeclaredFields()`, which is undefined.
 */

import java

class CompareToBuilderClass extends Class {
    CompareToBuilderClass() {
        hasQualifiedName(["org.apache.commons.lang.builder", "org.apache.commons.lang3.builder"], "CompareToBuilder")
    }
}

class ReflectionCompareMethod extends Method {
    ReflectionCompareMethod() {
        getDeclaringType() instanceof CompareToBuilderClass
        and hasName("reflectionCompare")
    }
}

from MethodAccess reflectionCompareCall, Expr argument, Class superclass, Field inheritedField
where
    reflectionCompareCall.getMethod() instanceof ReflectionCompareMethod
    and argument = reflectionCompareCall.getArgument([0, 1])
    and superclass = argument.getType().(RefType).getSourceDeclaration().getASourceSupertype+()
    and inheritedField = superclass.getAField()
    // Only consider fields in source; using reflectionCompare on third party class is covered by separate query
    and inheritedField.fromSource()
    and not inheritedField.isStatic()
    // Ignore if superclass uses reflectionCompare
    and not exists(MethodAccess superReflectionCompareCall |
        superReflectionCompareCall.getMethod() instanceof ReflectionCompareMethod
        and superReflectionCompareCall.getEnclosingCallable().getDeclaringType() = superclass
    )
select argument, "Accesses fields of superclass $@ which might not have been intended for reflective comparison", superclass, superclass.getName()
