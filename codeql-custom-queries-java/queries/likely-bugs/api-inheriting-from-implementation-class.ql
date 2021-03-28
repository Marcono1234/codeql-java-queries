/**
 * Finds cases where a publicly facing class extends a non-publicly facing type and
 * by that implicitly exposes members of the non-publicly facing type. E.g.:
 * ```java
 * private static class Implementation {
 *     protected void helperMethod() {
 *         ...
 *     }
 * }
 * 
 * // Accidentially exposes `helperMethod()` inherited from class Implementation
 * public static class PublicClass extends Implementation {
 *     ...
 * }
 * ```
 * 
 * In most cases this is not intended and accidentially exposes internal
 * implementation members. Even if this is intended, it might be cleaner to
 * have a public API interface, a private implementation class implementing
 * the interface and then the public class extending the private implementation:
 * ```
 * PublicClass > PrivateImplementation > PublicInterface
 * ```
 * 
 * @kind problem
 */

import java
import lib.Visibility
import lib.TopLevelVisibility

predicate isPubliclyVisible(RefType t) {
    getTopLevelVisibility(t).isVisibleToOtherModules()
    and getEffectiveVisibility(t).isProtectedOrHigher()
}

private string getMemberDisplayName(Member m, string memberTypeName) {
    if m instanceof Field then memberTypeName = "field" and result = m.getName()
    else if m instanceof Method then memberTypeName = "method" and result = m.(Method).getStringSignature()
    else if m instanceof NestedType then memberTypeName = "member type" and result = m.getName()
    // Default case, so even if the above is not covering a type it will still appear in the results
    else (memberTypeName = "member" and result = m.toString())
}

class InternalTypePubliclyVisibleMember extends Member {
    InternalTypePubliclyVisibleMember() {
        getMemberVisibility(this).isProtectedOrHigher()
        // Ignore constructors, they are not inherited
        and not this instanceof Constructor
        and not isPubliclyVisible(getDeclaringType().(ClassOrInterface))
    }

    Visibility getVisibility() {
        result = getMemberVisibility(this)
    }

    predicate overridesMethodOfPubliclyVisibleType() {
        exists (Method overridden | this.(Method).getSourceDeclaration().overridesOrInstantiates+(overridden) |
            isPubliclyVisible(overridden.getDeclaringType())
            // And make sure that overridden is visible as well, otherwise it might be
            // a package-private method whose visibility is increased by this method
            and getMemberVisibility(overridden).isProtectedOrHigher()
        )
    }
}

// Note: Cannot use RefType.inherits(Member) because that does not consider nested classes,
// see https://github.com/github/codeql/issues/5596
from Class inheritingType, ClassOrInterface declaringType, InternalTypePubliclyVisibleMember inheritedMember, string memberTypeName, string memberName
where
    inheritingType.fromSource()
    // Only consider publicly visible types
    and isPubliclyVisible(inheritingType)
    and not inheritingType instanceof TestClass
    and declaringType = inheritedMember.getDeclaringType().getSourceDeclaration()
    // Member is inherited (declared by one of the supertypes)
    and inheritingType.getASourceSupertype+() = declaringType
    // Ignore if inherited implementation member is overridden by public type
    and not exists(Method overriding |
        overriding.getSourceDeclaration().overridesOrInstantiates+(inheritedMember)
        and isPubliclyVisible(overriding.getDeclaringType())
        and overriding.getDeclaringType() = inheritingType.getASourceSupertype*()
    )
    // Ignore if implementation type overrides method from public type
    // E.g. PublicClass > PrivateImplementation > PublicInterface
    and not inheritedMember.overridesMethodOfPubliclyVisibleType()
    // If inherited method itself overrides publicly visible method of other non-public type
    // only report the overridden but not this, except if it increases the visibility
    and not exists(InternalTypePubliclyVisibleMember overridden |
        inheritedMember.(Method).getSourceDeclaration().overridesOrInstantiates+(overridden)
        and overridden.getVisibility().hasSameRank(inheritedMember.getVisibility())
    )
    and memberName = getMemberDisplayName(inheritedMember, memberTypeName)
select inheritingType, "Inherits " + memberTypeName + " $@ from non-publicly visible type $@",
    inheritedMember, memberName, declaringType, declaringType.getName()
