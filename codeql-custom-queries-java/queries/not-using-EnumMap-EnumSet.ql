/**
 * Finds creations of `HashMap` and `HashSet` where the specialized enum variants
 * `EnumMap` respectively `EnumSet` could be used instead.
 */

import java

string getAlternative(ClassInstanceExpr newExpr) {
    exists (ParameterizedClass parameterized, GenericType generic |
        parameterized = newExpr.getConstructedType()
        and generic = parameterized.getGenericType()
        and (
            (
                generic.hasQualifiedName("java.util", "HashMap")
                and parameterized.getTypeArgument(0) instanceof EnumType // Map key
                and result = "EnumMap"
            )
            or (
                generic.hasQualifiedName("java.util", "HashSet")
                and parameterized.getTypeArgument(0) instanceof EnumType // Set element
                and result = "EnumSet"
            )
        )
    )
}

from ClassInstanceExpr newExpr, string alternative
where
    alternative = getAlternative(newExpr)
select newExpr, alternative
