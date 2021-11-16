/**
 * Finds cast expressions which cast to a specific parameterized `Class` type,
 * for example `Class<Number>`. Performing such a cast can be unsafe and lead
 * to confusing `ClassCastException` later when the cast class instance actually
 * had a different type.
 * 
 * Instead of such a cast if possible `Class.asSubclass` should be used which
 * makes sure the classes are actually assignable.
 */

// TODO: Causes a large number of false positives

import java

predicate referencesTypeVariable(Type t) {
    t instanceof TypeVariable
    or referencesTypeVariable(t.(Array).getElementType())
    or referencesTypeVariable(t.(ParameterizedType).getATypeArgument())
    or exists(Wildcard wildcard | wildcard = t |
        referencesTypeVariable(wildcard.getLowerBoundType())
        or referencesTypeVariable(wildcard.getUpperBoundType())
    )
}

from CastExpr cast, ParameterizedClass castType
where
    castType = cast.getType()
    and castType.getSourceDeclaration() instanceof TypeClass
    // Ignore cast to `Class<?>`
    and exists(Type typeArgument | typeArgument = castType.getTypeArgument(0) |
        not typeArgument instanceof Wildcard
    )
    and (
        // Either not referencing any type variable, so could rewrite this to use
        // asSubclass call with type literal
        not referencesTypeVariable(castType)
        // Or parameter has the same type; could use that for asSubclass call
        or exists(Parameter param |
            param = cast.getEnclosingCallable().getAParameter()
            and param.getType() = castType
        )
    )
select cast, "Unsafe cast, should use `Class.asSubclass(...)` if possible"
