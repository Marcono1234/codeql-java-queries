/**
 * Finds overloaded methods declared by generic types which could cause conflicts
 * for subclasses for certain type arguments. For example:
 * ```java
 * class C<T> {
 *     void consume(String s) {
 *         ...
 *     }
 *
 *     void consume(T t) {
 *         ...
 *     }
 * }
 * ```
 * Then it would be impossible to implement a subclass `Subclass extends C<String>`
 * because the overloaded methods would conflict.
 * 
 * @kind problem
 */

import java
import lib.Types

predicate isVisibleToSubclass(Method m) {
    m.isProtected()
    or m.isPublic()
}

from GenericType t, Method nonGenericMethod, Method genericMethod
where
    t.fromSource()
    and isPubliclySubclassable(t)
    // TODO: Could maybe expand this consider methods declared in supertypes as well (?)
    and nonGenericMethod.getDeclaringType() = t
    and genericMethod.getDeclaringType() = t
    // And methods are overloads
    and nonGenericMethod.getName() = genericMethod.getName()
    and nonGenericMethod.getNumberOfParameters() = genericMethod.getNumberOfParameters()
    and isVisibleToSubclass(nonGenericMethod)
    and isVisibleToSubclass(genericMethod)
    // And generic method has as parameter type variable whose bound is supertype of parameter
    // type of non generic method
    and exists(int paramIndex, TypeVariable typeVar |
        typeVar = genericMethod.getParameterType(paramIndex)
        and typeVar = t.getATypeParameter()
    |
        nonGenericMethod.getParameterType(paramIndex).(RefType).getSourceDeclaration().getASourceSupertype() = typeVar.getErasure()
        // And all other parameter types are the same
        and forall(int otherParamIndex |
            otherParamIndex != paramIndex
            and otherParamIndex = [0 .. nonGenericMethod.getNumberOfParameters() - 1]
        |
            nonGenericMethod.getParameterType(otherParamIndex).getErasure() = genericMethod.getParameterType(otherParamIndex).getErasure()
        )
    )
    and nonGenericMethod != genericMethod
    and not nonGenericMethod.isStatic()
    // Ignore if one or both methods are abstract interface methods, then subclass can apparently
    // implement both as a single method (could still cause problems for parameterized types though,
    // e.g. non-generic: List<String> and T: List<Number>)
    and not (
        t instanceof Interface
        and (
            nonGenericMethod.isAbstract()
            or genericMethod.isAbstract()
        )
    )
select nonGenericMethod, "Can cause conflicts for subtypes due to $@ overloaded method", genericMethod, "this"
