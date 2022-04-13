/**
 * Finds `protected` members which could have a lower visibility, for example package-private
 * or `private`. If a class or interface cannot have any public subclasses, then such
 * `protected` members might be confusing because they appear in the documentation but cannot
 * actually be used by external classes.
 * 
 * Note that sometimes for internal classes it might be desired to have `protected` members
 * to indicate that they could be accessed if an internal subclass was added in the future.
 */

import java

from ClassOrInterface declaringType, Member member
where
    member.fromSource()
    and member.getDeclaringType() = declaringType
    and member.isProtected()
    and (
        declaringType.isFinal()
        // Or no accessible constructor exists
        or forall(Constructor c | c.getDeclaringType() = declaringType |
            c.isPrivate() or c.isPackageProtected()
        )
    )
    // And no subclass exists (e.g. in same compilation unit)
    and not exists(ClassOrInterface subclass |
        subclass.getASourceSupertype+() = declaringType
    )
    // And if member is method, there exists no overridden method which requires it to be protected
    and not exists(Method overridden |
        member.(Method).getASourceOverriddenMethod+() = overridden
        and overridden.isProtected()
    )
    and not declaringType instanceof TestClass
select member, "Member could have lower visibility"
