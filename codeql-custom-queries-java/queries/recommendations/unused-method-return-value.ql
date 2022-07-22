/**
 * Finds methods whose return value is not used by any of the callers. This
 * indicates that the return value might not be useful and the method could
 * be changed to have `void` as return type instead.
 * 
 * @kind problem
 */

import java

predicate isPubliclyVisible(RefType t) {
    (t.isProtected() or t.isPublic())
    and (exists(t.getEnclosingType()) implies isPubliclyVisible(t.getEnclosingType()))
}

from Method m
where
    not m.getReturnType() instanceof VoidType
    // Make sure method is called a few times to increase confidence that return value
    // is redundant
    and count(MethodAccess a | a.getMethod().getSourceDeclaration() = m) >= 2
    // And all calls discard result
    and forall(MethodAccess call | call.getMethod().getSourceDeclaration() = m |
        call instanceof ValueDiscardingExpr
    )
    // Ignore if method overrides other method and is therefore forced to have return value
    and not exists(m.getASourceOverriddenMethod())
    // To reduce false positives only consider methods which are not publicly visible
    and (
        m.isPrivate()
        or m.isPackageProtected()
        or (
            not isPubliclyVisible(m.getDeclaringType())
            // And there is no public subtype which exposes method
            and not exists(RefType subtype |
                subtype.getSourceDeclaration().getASourceSupertype*() = m.getDeclaringType()
                and isPubliclyVisible(subtype)
            )
        )
    )
    and not m.getAnAnnotation().getType().hasName("CanIgnoreReturnValue")
    // Make sure method actually returns a value and is not a utility method which
    // always throws exception
    and count(ReturnStmt r | r.getEnclosingCallable() = m) >= 1
    // Ignore if method looks like a validation method which for convenience returns
    // the provided argument
    and not forall(ReturnStmt r | r.getEnclosingCallable() = m |
        r.getResult().(RValue).getVariable() = m.getAParameter()
    )
    // Ignore if method returns `this` to allow using it for method chaining
    and not forall(ReturnStmt r | r.getEnclosingCallable() = m |
        r.getResult().(ThisAccess).isOwnInstanceAccess()
        // Or casting `this`, e.g.: `return (T) this;`
        or r.getResult().(CastExpr).getExpr().(ThisAccess).isOwnInstanceAccess()
    )
select m, "Method return value is not used by callers"
