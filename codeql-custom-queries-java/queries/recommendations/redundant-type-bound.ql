/**
 * Finds bounded types where the upper bound cannot be subtyped or
 * where the lower or upper bound is `Object`, e.g.:
 * ```
 * // String cannot be subclassed so this will always be a `List<String>`
 * List<? extends String> strings;
 * ```
 *
 * An upper bound which cannot be subtyped is redundant because the
 * type will then always be the type of the upper bound.
 * A bound of type `Object` is redundant as well. For a lower bound of
 * type `Object` the bounded type should be replaced with `Object`:
 * `? super Object` -> `Object`
 * For an upper bound of type `Object` the bound should be omitted:
 * `? extends Object` -> `?`
 */

import java

predicate cannotBeSubtyped(RefType type) {
    (
        type.isFinal()
        or (
            forall (Constructor constructor | constructor = type.getAConstructor() |
                constructor.isPrivate()
            )
            // If all constructors are private and class is nested class, then
            // another nested class could still extend it
            and not any (RefType t).getASourceSupertype+() = type
        )
    )
    // For ParameterizedType also make sure all type arguments cannot be subtyped
    // E.g. `? extends Optional<String>` makes no sense, but `? extends Optional<Number>`
    // does
    and if type instanceof ParameterizedType then (
        cannotBeSubtyped(type.(ParameterizedType).getGenericType())
        and forall (RefType typeArg | typeArg = type.(ParameterizedType).getATypeArgument() |
            cannotBeSubtyped(typeArg)
        )
    ) else if type instanceof TypeVariable then (
        cannotBeSubtyped(type.(TypeVariable).getAnUltimateUpperBoundType())
    ) else if type instanceof Array then (
        cannotBeSubtyped(type.(Array).getElementType())
    ) else any()
}

from Element source, BoundedType boundedType, RefType bound, string reason
where
    boundedType.hasTypeBound()
    and not boundedType.(Wildcard).isUnconstrained()
    and (
        if boundedType.fromSource() then source = boundedType
        // Causes some false positives due to https://github.com/github/codeql/issues/3648
        else source.(TypeAccess).getATypeArgument().getType() = boundedType
    )
    and (
        (
            bound = boundedType.getUpperBoundType()
            and cannotBeSubtyped(bound)
            and reason = "Bound cannot be subtyped"
        )
        or (
            // Covers lower and upper bounds
            bound = boundedType.getATypeBound().getType()
            and bound instanceof TypeObject
            and reason = "Using Object as bound is redundant"
        )
    )
select source, boundedType, bound, reason
