/**
 * Finds cast expressions which cast to parameterized `java.lang.Class`, where the
 * type argument contains more information than it is available at runtime,
 * e.g. `(Class<List<String>>) c`.
 * 
 * Casting to such `Class` types is error-prone because due to type-erasure only
 * at most the direct type argument of `Class<...>` is present at runtime,
 * e.g. `List`, when using a parameterized type such as `List<String>` its type
 * arguments are not present at runtime.  
 * The result of the cast expression therefore creates a false sense of security,
 * making it look like methods of `Class` such as `cast(Object)` enforce this type
 * argument, while in reality they don't do this.
 */

import java

/*
 * Note: Using type variable can be error-prone as well, e.g. when `T` is `List<String>`
 * performing cast to `Class<T>` would result in `Class<List<String>>`
 * However, often it is used in a safe way (or without alternatives); therefore don't
 * report this because it would cause too many false positives
 */

from CastExpr castExpr, ParameterizedType classType, RefType classTypeArg
where
    classType = castExpr.getType()
    and classType.getSourceDeclaration() instanceof TypeClass
    // Get `T` of `Class<T>`
    and classTypeArg = classType.getTypeArgument(0)
    // And uses parameterized type with non-wildcard type arguments
    and exists(RefType unsafeTypeArg |
        // Get `T` of `Class<MyGenericClass<T>>`; can't directly check result
        // with `not ...` since this would also erroneously match non-parameterized
        // type arguments, e.g. `Class<String>`
        unsafeTypeArg = classTypeArg.(ParameterizedType).getATypeArgument()
        // Only wildcard is safe as type argument, e.g. `Class<List<?>>`
        and not unsafeTypeArg instanceof Wildcard
    )
select castExpr, "Casts to error-prone Class type " + classType.getName()
