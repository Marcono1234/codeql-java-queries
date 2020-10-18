/**
 * Finds generic methods where the return type is a type variable of the method, but
 * the type variable is not bound by the arguments of the method:
 * ```
 * <T> T getValue(String key);
 * ```
 * Such a method makes usage of it inherently unsafe because the caller can write code
 * which expects any return type even though the method cannot actually satisfy this.
 *
 * Note that in some situations such methods might be acceptable, for example when the
 * method returns an object which is created using a given `Class` argument. Since Java
 * class literals for generic types (e.g. `List.class`) produce raw generic class
 * references, using them as argument would be cumbersome if the method return type was
 * not unbound.
 */

import java

predicate isReferencedByParam(TypeVariable typeVar, GenericMethod m) {
    exists (TypeAccess paramTypeAccess | paramTypeAccess.getParent+() = m.getAParameter() |
        paramTypeAccess.getType() = typeVar
    )
}

from GenericMethod m, TypeVariable typeVar
where
    m.fromSource()
    and typeVar = m.getATypeParameter()
    and m.getReturnType() = typeVar
    // Make sure method actually returns something; ignore methods which always throw
    and exists (ReturnStmt returnStmt | returnStmt.getEnclosingCallable() = m)
    // Ignore if parameter references typeVar
    and not isReferencedByParam(typeVar, m)
    // Ignore if other TypeVariable has typeVar as bound and is referenced by parameter
    and not exists (TypeVariable otherTypeVar |
        otherTypeVar = m.getATypeParameter()
        and otherTypeVar.getAnUltimateUpperBoundType() = typeVar
        and isReferencedByParam(otherTypeVar, m)
    )
select m, "Unbound return type"
