/**
 * Finds inner classes (i.e. non-static nested classes) which do not
 * access the enclosing class and could therefore be static.
 */

import java

RefType getAnEnclosingNonStatic(RefType inner) {
    result = inner.getEnclosingType()
    and not result.isStatic()
}

predicate referencesEnclosing(InnerClass inner) {
    exists (RefType enclosing |
        enclosing = getAnEnclosingNonStatic(inner)
        |
        exists (ThisAccess thisAccess |
            thisAccess.getType() = enclosing 
        )
        or exists (FieldAccess fieldAccess |
            not fieldAccess.getField().isStatic()
            and fieldAccess.isEnclosingFieldAccess(enclosing)
        )
        or exists (MethodAccess methodAccess |
            not methodAccess.getMethod().isStatic()
            and methodAccess.isEnclosingMethodAccess(enclosing)
        )
    )
}

from InnerClass innerClass
where
    // TODO: Maybe only check innerClasses whose direct enclosing class
    // is static, since otherwise class would have to be moved to become
    // static, which might not be desirable; then also remove `getAnEnclosingNonStatic`

    // These cannot be static
    not (innerClass.isAnonymous() or innerClass.isLocal())
    and not referencesEnclosing(innerClass)
select innerClass
