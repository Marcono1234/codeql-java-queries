/**
 * Finds code which creates a Gson `TypeToken` which captures a type variable, for example
 * `new TypeToken<List<T>>() {}`. Such code is not actually type safe and can cause issues
 * when used with Gson for both serialization and deserialization because at runtime due
 * to type erasure the actual type of `T` is not available but only its bound (if not
 * explicitly specified it is `Object`).
 * 
 * A solution to this can be either to construct the `TypeToken` with the actual type
 * argument in case it is known in advance, for example `TypeToken<List<String>>`.
 * Otherwise, when constructing a `TypeToken<T>` the code should be refactored to instead
 * take a `TypeToken` as argument and let the caller create that actual token. When creating
 * a `TypeToken<List<T>>` the method `TypeToken.getParameterized` can be used, for example:
 * ```java
 * TypeToken.getParameterized(List.class, elementType)
 * ```
 * 
 * Alternatively when using Kotlin the type variable can be made `reified`; this makes sure
 * the actual type is captured by the `TypeToken`.
 * 
 * @kind problem
 */

import java

private TypeVariable getAReferencedTypeVariable(Type t) {
    result = t
    or result = t.(ParameterizedType).getATypeArgument()
    or result = t.(Array).getComponentType()
    // Don't have to consider other types (e.g. intersection type) for now because they cannot appear when creating TypeToken subclass
}

// Note: Don't report TypeAccess of type variable because it might not exist explicitly when type is inferred
from AnonymousClass typeTokenCreation, ParameterizedClass parameterizedTypeToken, TypeVariable typeVariable
where
    typeTokenCreation.getASupertype() = parameterizedTypeToken
    and parameterizedTypeToken.getSourceDeclaration().hasQualifiedName("com.google.gson.reflect", "TypeToken")
    and typeVariable = getAReferencedTypeVariable(parameterizedTypeToken)
    // Ignore Kotlin reified type variable because that is actually safe
    and not typeVariable.isReified()
select typeTokenCreation, "Capturing type variable $@ is not type safe", typeVariable, typeVariable.getName()
