/**
 * Finds wildcards with bounds which make no sense:
 * ```
 * class BaseClass {}
 * class SubClass extends BaseClass {}
 * class GenericClass<T extends SubClass> {}
 *
 * ...
 *
 * // The wildcard bound makes no sense because the type variable of
 * // GenericClass requires at least SubClass as type argument, so only
 * // SubClass (or one of its subtypes) can be used as type argument
 * void doSomething(GenericClass<? extends BaseClass> param) {
 *     ...
 * }
 *
 * // The wildcard bound makes no sense because the type variable of
 * // GenericClass requires at least SubClass as type argument, so a
 * // a supertype of SubClass cannot be used as type argument
 * void doSomething(GenericClass<? super SubClass> param) {
 *     ...
 * }
 * ```
 *
 * While these bounds are permitted by the compiler, they have no effect
 * and are likely confusing to another person reading the code.
 *
 * See also https://bugs.openjdk.java.net/browse/JDK-8250936
 */

import java

TypeVariable getTypeVariable(WildcardTypeAccess wildcardTypeAccess) {
    exists (TypeAccess typeAccess, ParameterizedType paramType, int typeArgIndex |
        typeAccess.getType() = paramType
        and typeAccess.getTypeArgument(typeArgIndex) = wildcardTypeAccess
        and result = paramType.getGenericType().getTypeParameter(typeArgIndex)
    )
}

from WildcardTypeAccess wildcardTypeAccess, TypeVariable typeVar, RefType typeVarBound, string reason
where
    getTypeVariable(wildcardTypeAccess) = typeVar
    // Make sure type var actually has bound, otherwise Object is returned as upper
    // bound which would cause false positives
    and typeVar.hasTypeBound()
    and typeVarBound = typeVar.getAnUltimateUpperBoundType()
    and (
        (
            wildcardTypeAccess.getUpperBound().getType() = typeVarBound.getASupertype()
            and reason = "Upper bound is a supertype of type variable bound."
        )
        or wildcardTypeAccess.getLowerBound().getType() = typeVarBound
        and reason = "Lower bound is same as upper bound of type variable."
    )
select wildcardTypeAccess, "Wildcard has illogical bound for $@: " + reason, typeVar, "this type variable"
