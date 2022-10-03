/**
 * Finds stateless classes which could define a singleton constant.
 */

import java

from Class c
where
    c.isStatic()
    and not c.isAbstract()
    // Class does not extend other class (that class could
    // change in the future and become stateful)
    and not exists (RefType superType |
        superType = c.getASupertype+()
        and not superType instanceof TypeObject
        and not superType instanceof Interface
    )
    // A non-private constructor exists, otherwise it might be an
    // utility class
    and exists (Constructor constructor |
        constructor = c.getAConstructor()
        and not c.isPrivate()
    )
    // A non-static method exists
    and exists (Method m |
        m = c.getAMethod()
        and not m.isStatic()
    )
    // No non-static fields exist, since that would make the class
    // stateful
    and not exists (Field f |
        f.getDeclaringType() = c
        and not f.isStatic()
    )
    // No singleton instance field exists
    and not exists (Field f |
        f.getDeclaringType() = c
        and f.getAnAssignedValue().(ClassInstanceExpr).getConstructedType() = c
    )
    // Class is not referenced by annotation (annotation might require
    // that no-arg constructor exists and does not use singleton constant)
    and not exists (Annotation annotation |
        annotation.getTypeValue(_) = c
        or annotation.getATypeArrayValue(_) = c
    )
select c
