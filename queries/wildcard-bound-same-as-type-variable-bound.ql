/**
 * Finds wildcards which have the same upper bound as the type variable they
 * are a type argument for:
 * ```
 * class GenericClass<T extends CharSequence> {}
 *
 * ...
 *
 * // Wildcard bound is the same as type variable bound
 * void doSomething(GenericClass<? extends CharSequence> param) {
 *     ...
 * }
 * ```
 * In these cases the type bound of the wildcard is redundant. Instead an
 * unbounded wildcard `?` could be used.
 */

import java

TypeVariable getTypeVariable(WildcardTypeAccess wildcardTypeAccess) {
    exists (TypeAccess typeAccess, ParameterizedType paramType, int typeArgIndex |
        typeAccess.getType() = paramType
        and typeAccess.getTypeArgument(typeArgIndex) = wildcardTypeAccess
        and result = paramType.getGenericType().getTypeParameter(typeArgIndex)
    )
}

from WildcardTypeAccess wildcardTypeAccess, RefType wildcardBound, TypeVariable typeVar, RefType typeVarBound
where
    getTypeVariable(wildcardTypeAccess) = typeVar
    and wildcardBound = wildcardTypeAccess.getUpperBound().getType()
    // Ignore Object as bound because that is covered by a separate query
    and not wildcardBound instanceof TypeObject
    and typeVarBound = typeVar.getAnUltimateUpperBoundType()
    and wildcardBound = typeVarBound
select wildcardTypeAccess, "Wildcard has the same upper bound as $@; upper bound of wildcard is redundant.", typeVar, "this type variable"
