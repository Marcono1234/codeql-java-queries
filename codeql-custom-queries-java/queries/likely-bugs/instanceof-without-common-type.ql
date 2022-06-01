/**
 * Finds `instanceof` expressions which will most likely never evaluate to `true` because
 * the project contains no type which satisfies both type requirements.
 * 
 * This query might produce false positives in case there is externally a type which
 * implements both of types checked by the `instanceof` expression, or if types which
 * satisfy both requirements are created during runtime, for example as proxy classes.
 */

// Slightly similar to CodeQL's java/contradictory-type-checks

import java

from InstanceOfExpr instanceofExpr, RefType argType, RefType checkedType
where
    argType = instanceofExpr.getExpr().getType().(RefType).getSourceDeclaration()
    // Require that type exists in source form; otherwise common subtype might exist in other library
    and argType.fromSource()
    and not argType instanceof TypeVariable
    and checkedType = instanceofExpr.getCheckedType().getSourceDeclaration()
    // Require that type exists in source form; otherwise common subtype might exist in other library
    and checkedType.fromSource()
    // And there is no type which implements both the arg type and the checked type
    and not exists(RefType subtype |
        subtype.getASourceSupertype*() = argType
        and subtype.getASourceSupertype*() = checkedType
    )
    // Reduce false positives by ignoring case where both types are publicly visible interfaces
    // TODO: Maybe include these in results again (in separate query?) because they are relevant
    //       for projects which are not expected to be extended externally
    and not (
        (argType.isProtected() or argType.isPublic())
        and (checkedType.isProtected() or checkedType.isPublic())
        and argType instanceof Interface
        and checkedType instanceof Interface
    )
select instanceofExpr, "Check cannot succeed because project contains no type which is both $@ and $@",
    argType, argType.getName(), checkedType, checkedType.getName()
