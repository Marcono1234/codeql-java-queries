/**
 * Finds methods which appear to be leaking a field value which is defensively copied
 * by other methods, e.g.:
 * ```
 * public File {
 *     private final Set<String> owners;
 *
 *     ...
 *
 *
 *     public Set<String> getOwners() {
 *         // Good: Creates a defensive copy
 *         return new HashSet<>(owners);
 *     }
 *
 *     public boolean areOwners(Set<String> toTest) {
 *         // Bad: `owners` value is not copied (or wrapped) before being passed to `equals`,
 *         //      `toTest` might have malicious implementation which modifies argument
 *         return toTest.equals(owners);
 *     }
 * }
 * ```
 *
 * A defensive copy indicates that the field value might be mutable and that the class
 * does not want any caller to be able to modify it. However, failing to create a
 * defensive copy at one place could allow such modifications.
 */

import java
import semmle.code.java.dataflow.DataFlow

predicate createsClone(Expr expr, Field f) {
    exists (ClassInstanceExpr newExpr | newExpr = expr |
        newExpr.getAnArgument() = f.getAnAccess()
        // Make sure there are no other arguments
        and newExpr.getNumArgument() = 1
    )
    or exists (MethodAccess cloneCall | cloneCall = expr |
        cloneCall.getQualifier() = f.getAnAccess()
        and cloneCall.getMethod() instanceof CloneMethod
    )
    or createsClone(expr.(CastExpr).getExpr(), f)
}

predicate isPubliclySubclassable(ClassOrInterface type) {
    not type.isFinal()
    and isPubliclyVisible(type)
    and (
        type instanceof Interface
        or exists (Constructor constructor |
            constructor.getDeclaringType() = type
            and (constructor.isPublic() or constructor.isProtected())
        )
    )
}

predicate isTypePubliclyVisible(ClassOrInterface type) {
    (type.isPublic() or type.isProtected())
    and (
        not exists (type.getEnclosingType())
        or isTypePubliclyVisible(type.getEnclosingType())
    )
}

predicate isPubliclyVisible(Member member) {
    (
        member.isPublic()
        or (
            member.isProtected()
            and isPubliclySubclassable(member.getDeclaringType())
        )
    )
    and isTypePubliclyVisible(member.getDeclaringType())
}

from Field f, Method copyingGetter, Method leakingMethod, Expr leakingExpr
where
    not isPubliclyVisible(f)
    // Method name does not sound like its purpose is to copy the field value
    and not copyingGetter.getName().regexpMatch(".*[cC](?:lone|opy).*")
    and exists (Block body, ReturnStmt returnStmt |
        body = copyingGetter.getBody()
        and returnStmt.getEnclosingStmt() = body
        and count (Stmt stmt | stmt = body.getAStmt() and not stmt instanceof AssertStmt) = 1
    |
        copyingGetter.getReturnType() = f.getType().(RefType).getASourceSupertype*()
        and createsClone(returnStmt.getResult(), f)
    )
    and isPubliclyVisible(leakingMethod)
    and (
        exists (ReturnStmt returnStmt |
            returnStmt.getEnclosingCallable() = leakingMethod
            and leakingExpr = returnStmt.getResult()
        )
        // Or field value is passed to overridable method of leakingMethod argument
        or exists (MethodAccess call, Method called |
            call.getQualifier() = leakingMethod.getAParameter().getAnAccess()
            and leakingExpr = call.getAnArgument()
            // Consider overrides here as well
            and called.getAnOverride*() = call.getMethod()
            and called.isOverridable()
            and isPubliclySubclassable(called.getDeclaringType())
        )
    )
    and DataFlow::localFlow(DataFlow::exprNode(f.getAnAccess()), DataFlow::exprNode(leakingExpr))
select leakingExpr, "Field $@ is defensively copied by $@ but leaked directly by $@ of $@.",
    f, f.getName(),
    copyingGetter, copyingGetter.toString(),
    leakingExpr, "this expression",
    leakingMethod, leakingMethod.toString()
