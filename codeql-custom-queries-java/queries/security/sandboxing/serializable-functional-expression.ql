/**
 * Finds functional expressions which either implement a serializable
 * interface or are made serializable with an intersection type cast.
 *
 * If a class contains such a functional expression, it is possible
 * to access any of its methods (including private ones) by deserializing
 * a forged `SerializedLambda`.
 * See also https://stackoverflow.com/q/25443655/
 */

import java

from FunctionalExpr funcExpr, string reason
where
    // Check if implemented interface extends Serializable
    exists (RefType declaringType |
        declaringType = funcExpr.asMethod().getDeclaringType()
        and declaringType.getAnAncestor() instanceof TypeSerializable
        and reason = "Functional expression implements serializable interface"
    )
    // Or if functional expression is made serializable with intersection
    // type cast: (Serializable & Runnable) () -> { ... }
    or exists (CastExpr castExpr, IntersectionTypeAccess intersectionTypeAccess |
        castExpr.getTypeExpr() = intersectionTypeAccess
        and intersectionTypeAccess.getABound().getType().(RefType).getAnAncestor() instanceof TypeSerializable
        and castExpr.getExpr() = funcExpr
        and reason = "Function expression is made serializable"
    )
select funcExpr, reason
