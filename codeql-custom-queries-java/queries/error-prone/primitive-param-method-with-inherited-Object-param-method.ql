/**
 * Finds methods with primitive parameter type declared by a class which also inherits
 * a method overload with `Object` as type. Often such methods have different behavior,
 * but a caller might accidentally call the method with primitive parameter when they
 * provide a boxed primitive as argument.
 * 
 * A prominent example for this is the `java.util.List` interface which declares the
 * method `remove(int)` to remove the element at the specified index, but inherits the
 * method `remove(Object)` which removes the specified element. Calling
 * `remove(4)` removes the element at index 4, even though the intention of the caller
 * might have been to remove the element 4.
 * 
 * To avoid such issues the method with primitive parameter should be named differently.
 *
 * This query was inspired by Effective Java, Third Edition:
 * "Item 52: Use overloading judiciously"
 * 
 * @kind problem
 */

// TODO: Maybe also consider TypeVariable instead of Object as parameter where TypeVariable
// bound is same or supertype of boxed primitive

import java

from Method primitiveMethod, Method objectMethod
where
    primitiveMethod.fromSource()
    and primitiveMethod.isPublic()
    and objectMethod.isPublic()
    and primitiveMethod.getName() = objectMethod.getName()
    and primitiveMethod.getNumberOfParameters() = objectMethod.getNumberOfParameters()
    and exists(int objectParamIndex |
        objectMethod.getParameterType(objectParamIndex) instanceof TypeObject
        and primitiveMethod.getParameterType(objectParamIndex) instanceof PrimitiveType
        // And all parameter types are the same
        and forall(int otherIndex |
            otherIndex = [0..primitiveMethod.getNumberOfParameters() - 1]
            and otherIndex != objectParamIndex
        |
            primitiveMethod.getParameterType(otherIndex) = objectMethod.getParameterType(otherIndex)
        )
    )
    // And objectMethod is declared in supertype (this also makes it less likely that both
    // methods behave the same, which would be a false positive for this query)
    and primitiveMethod.getDeclaringType().getASourceSupertype+() = objectMethod.getDeclaringType()
    and not exists(primitiveMethod.getASourceOverriddenMethod())
    and not exists(objectMethod.getASourceOverriddenMethod())
select primitiveMethod, "Could be confused with overloaded method $@ which accepts the boxed type", objectMethod, objectMethod.getDeclaringType().getName() + "." + objectMethod.getStringSignature()
