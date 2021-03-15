/**
 * Finds intersection types (as part of cast expressions or type variable
 * declarations) which have redundant bound which is already covered by
 * a different bound. E.g.:
 * ```
 * // Bound `Serializable` is redundant because `Number` already implements `Serializable`
 * return (Number & Serializable) obj;
 * ```
 */

import java

private Element getIntersectionTypeWithRedundantBound(RefType redundant, RefType includingRedundant) {
    (
        // IntersectionTypeAccess does not cover intersection type of TypeVariable
        // (at least currently, see https://github.com/github/codeql/issues/5404)
        exists(TypeVariable v | v = result |
            redundant = v.getUpperBoundType()
            and includingRedundant = v.getUpperBoundType()
        )
        or exists(IntersectionTypeAccess t | t = result |
            redundant = t.getABound().getType()
            and includingRedundant = t.getABound().getType()
        )
    )
    and includingRedundant.getASourceSupertype+() = redundant
}

from Element intersectionType, RefType redundant, RefType includingRedundant
where
    intersectionType = getIntersectionTypeWithRedundantBound(redundant, includingRedundant)
    and intersectionType.fromSource()
select intersectionType, "Has redundant bound $@ because it is already included by bound $@",
    redundant, redundant.toString(), includingRedundant, includingRedundant.toString()
