/**
 * Finds usage of one of the reflection based methods of Apache Commons Lang's `CompareToBuilder`,
 * `EqualsBuilder` and `HashCodeBuilder` which are used with a third party class, e.g. a JDK
 * class. Due to their usage of reflection, using them on third party classes makes the application
 * dependent on the implementation of the third party class. This can lead to incorrect results in
 * case the value of certain fields is irrelevant for equality, and it can make upgrading the
 * dependency on that third party library or switching to a Java version enforcing the Java Platform
 * Module System more difficult.
 */

import java

abstract class ReflectionBasedMethod extends Method {
    abstract int getAnAccessedObjectArgIndex();

    predicate isSpecialCasingArrays() {
        none()
    }
}

class CompareToBuilderClass extends Class {
    CompareToBuilderClass() {
        hasQualifiedName(["org.apache.commons.lang.builder", "org.apache.commons.lang3.builder"], "CompareToBuilder")
    }
}

class ReflectionCompareMethod extends ReflectionBasedMethod {
    ReflectionCompareMethod() {
        getDeclaringType() instanceof CompareToBuilderClass
        and hasName("reflectionCompare")
    }

    override
    int getAnAccessedObjectArgIndex() {
        result = [0, 1]
    }
}

class EqualsBuilderClass extends Class {
    EqualsBuilderClass() {
        hasQualifiedName(["org.apache.commons.lang.builder", "org.apache.commons.lang3.builder"], "EqualsBuilder")
    }
}

class ReflectionEqualsMethod extends ReflectionBasedMethod {
    ReflectionEqualsMethod() {
        getDeclaringType() instanceof EqualsBuilderClass
        and hasName([
            "reflectionEquals",
            // Also consider instance method
            "reflectionAppend",
        ])
    }

    override
    int getAnAccessedObjectArgIndex() {
        result = [0, 1]
    }

    override
    predicate isSpecialCasingArrays() {
        // EqualsBuilder has special array handling which performs non-reflective check
        any()
    }
}

class HashCodeBuilderClass extends Class {
    HashCodeBuilderClass() {
        hasQualifiedName(["org.apache.commons.lang.builder", "org.apache.commons.lang3.builder"], "HashCodeBuilder")
    }
}

class ReflectionHashCodeMethod extends ReflectionBasedMethod {
    ReflectionHashCodeMethod() {
        getDeclaringType() instanceof HashCodeBuilderClass
        and hasName("reflectionHashCode")
    }

    override
    int getAnAccessedObjectArgIndex() {
        if getParameterType(0).hasName("int") then result = 2
        else result = 0
    }
}

// Note: Don't consider ToStringBuilder or ReflectionToStringBuilder; maybe for debugging purposes user
// intentionally wants to get internal field values

from MethodAccess reflectionMethodCall, ReflectionBasedMethod reflectionMethod, Expr argument, string message, Type reportedType
where
    reflectionMethod = reflectionMethodCall.getMethod()
    and argument = reflectionMethodCall.getArgument(reflectionMethod.getAnAccessedObjectArgIndex())
    and (
        // Either argument type itself is third party class
        exists(Type argType | argType = argument.getType() |
            (
                reportedType = argType.(Class).getSourceDeclaration()
                // Would access fields of wrapper type
                or reportedType = argType.(PrimitiveType)
                or reportedType = argType.(Array)
            )
            // And assume it is third party class because it has no source file
            and not reportedType.fromSource()
            and not reportedType instanceof TypeObject
            and not (reportedType instanceof Array and reflectionMethod.isSpecialCasingArrays())
            and message = "Accesses fields of third party class $@"
        )
        // Or supertype of argument type is third party class
        or exists(RefType argType, Class superclass |
            argType = argument.getType()
            and argType.getSourceDeclaration().fromSource()
            and superclass = argType.getASourceSupertype+()
            and exists(Field superclassField |
                superclassField = superclass.getAField()
                and not superclassField.isStatic()
            )
            // And assume it is third party class because it has no source file
            and not superclass.fromSource()
            and reportedType = superclass
            and message = "Accesses fields inherited from third party class $@"
        )
    )
select argument, message, reportedType, reportedType.getName()
