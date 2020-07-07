/**
 * Finds type variables which shadow a type variable of an enclosing type
 * or method (in case of local classes), e.g.:
 * ```
 * class Map<K, V> {
 *     // Shadows type variables K and V of enclosing type
 *     private class MapEntry<K, V> {
 *         ...
 *     }
 * 
 *     ...
 *
 *     // This is fine because method is static and therefore
 *     // type variables of enclosing type are not effective here
 *     public static <K, V> Map<K, V> empty() {
 *         ...
 *     }
 * }
 * ```
 *
 * A type variable shadowing another type variable can be confusing to
 * another person reading the code. Often it indicates that there is no
 * need for a type variable because the type variables of the enclosing
 * type could be used (as seen in the example above), or that a method,
 * whose type variables shadow the variables of the declaring type,
 * could be static instead.
 */

import java

TypeVariable getShadowedTypeVar(TypeVariable var, Modifiable enclosing) {
    // Make sure they are not the same when LocalClass defining type var is provided
    result != var
    and result.getName() = var.getName()
    and (
        result.getGenericCallable() = enclosing
        or result.getGenericType() = enclosing
        or result = getShadowedTypeVar(var, enclosing.(LocalClass).getLocalClassDeclStmt().getEnclosingCallable())
        // Only consider enclosing of `enclosing` if not static because otherwise type
        // variables defined by it are not effective here
        or not enclosing.isStatic() and (
            // getEnclosingType() also works for LocalClass
            result = getShadowedTypeVar(var, enclosing.(ClassOrInterface).getEnclosingType())
            or result = getShadowedTypeVar(var, enclosing.(Callable).getDeclaringType())
        )
    )
}

from TypeVariable typeVar, TypeVariable shadowedVar
where
    typeVar.fromSource()
    and shadowedVar = getShadowedTypeVar(typeVar, [
        typeVar.getGenericCallable().(Modifiable),
        // Don't get declaring type here because for LocalClass, enclosing
        // callable is interesting as well
        typeVar.getGenericType()
    ])
select typeVar, shadowedVar
