/**
 * Finds enum types which have no enum constants, but have non-static members
 * (e.g. fields or methods) or explicit supertypes.
 * Since enums cannot be subclassed and their constructor is implicitly private,
 * it is impossible to create an instance of such an enum and therefore its
 * non-static members cannot be used.
 */

import java

// Note: Predicate is based on CodeQL's PrintAst.qll; rather fragile, but RefType
// has no predicates for directly getting supertype TypeAccess
TypeAccess getSuperTypeAccess(RefType t, RefType supertype) {
    result.getType() = supertype
    and result.getParent() = t
}

from EnumType e, string alertExplanation, Top alertExplanationElement, string alertExplanationElementName
where
    e.fromSource()
    // Ignore anonymous enum subclasses
    and not e instanceof AnonymousClass
    // Has no enum constants
    and not exists(e.getAnEnumConstant())
    and (
        // Has supertype
        exists(RefType supertype |
            e.getASupertype() = supertype
            // Ignore implicit Enum supertype
            and not supertype.getSourceDeclaration().hasQualifiedName("java.lang", "Enum")
            and alertExplanation = "has supertype $@"
            and alertExplanationElement = getSuperTypeAccess(e, supertype)
            and alertExplanationElementName = supertype.getName()
        )
        // Or has non-static member
        or exists(Member m | m = alertExplanationElement |
            m.getDeclaringType() = e
            and not m.isStatic()
            // Ignore default constructor
            and not m.(Constructor).isDefaultConstructor()
            and alertExplanation = "has non-static member $@"
            and alertExplanationElementName = m.getName()
        )
    )
select e, "Enum has no constants but " + alertExplanation, alertExplanationElement, alertExplanationElementName
