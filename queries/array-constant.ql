/**
 * Arrays (unless empty) are mutable and should not be used as constants.
 */

import java

predicate isPublicOrProtected(RefType t) {
    (t.isPublic() or t.isProtected())
    and (
        not exists(t.getEnclosingType())
        or isPublicOrProtected(t.getEnclosingType())
    )
}

predicate emptyArrayAssignment(Field f) {
    exists (ArrayCreationExpr newArr |
        f.getAnAssignedValue() = newArr
        and newArr.getFirstDimensionSize() = 0
    )
}

from Field f
where
    f.getType() instanceof Array
    and f.isStatic()
    // Empty array is immutable, so ignore it
    and not emptyArrayAssignment(f)
    and not (f.isPrivate() or f.isPackageProtected())
    and isPublicOrProtected(f.getDeclaringType())
select f
