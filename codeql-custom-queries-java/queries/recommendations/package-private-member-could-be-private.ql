/**
 * Finds package-private members which could be `private` instead. Reducing the visibility
 * can help to make sure that the internal implementation of classes in not by accident used
 * by other classes in the same package.
 */

import java

import lib.JavaDatabaseLib

private Expr getAMemberUsage(Member member) {
    result.(Call).getCallee().getSourceDeclaration() = member
    or result.(MemberRefExpr).getReferencedCallable().getSourceDeclaration() = member
    or result.(FieldAccess).getField() = member
    or result.(TypeAccess).getType() = member
}

from ClassOrInterface declaringType, Member member
where
    member.fromSource()
    and member.getDeclaringType() = declaringType
    and member.isPackageProtected()
    // And member is not used outside of compilation unit
    and not exists(Expr memberUsage |
        memberUsage = getAMemberUsage(member)
        and memberUsage.getCompilationUnit() != declaringType.getCompilationUnit()
    )
    // And MemberType is not subclassed outside of compilation unit
    and not exists(ClassOrInterface subclass |
        subclass.getASourceSupertype+() = member
        and subclass.getCompilationUnit() != declaringType.getCompilationUnit()
    )
    and (
        // Might be package-private to avoid compiler generated accessor methods
        not exists(Expr memberUsage |
            memberUsage = getAMemberUsage(member)
            and memberUsage.getEnclosingCallable().getDeclaringType() != declaringType
        )
        // Java 11 does not generate accessor methods anymore, see JEP 181: Nest-Based Access Control
        or isJava11OrNewer()
    )
    // And if member is method, there exists no overridden method which requires it to be package-private
    and not exists(Method overridden |
        member.(Method).getASourceOverriddenMethod+() = overridden
        and overridden.isPackageProtected()
    )
    and not declaringType instanceof TestClass
    // And member has no declared annotation which might indicate that at runtime member
    // is accessed through reflection and therefore needs to be package-private
    // TODO: Could refine this to only consider annotations with RUNTIME retention
    and not any(Annotation a).getAnnotatedElement() = member
select member, "Member could have lower visibility"
