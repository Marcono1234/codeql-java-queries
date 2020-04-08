/**
 * Finds unused parameters of non-overridable methods.
 */

import java

from Parameter p, Method m
where
    p = m.getAParameter()
    and not exists (VarAccess access | access.getVariable() = p)
    and not m instanceof MainMethod
    // Ignore overriding methods since they have to declare the same parameters
    and not exists(m.getAnOverride())
    and (
        not m.isOverridable()
        // Also consider parameter unused if method is package-private and
        // no other method is overriding it
        or (
            m.isPackageProtected()
            and not exists(Method other | other.getAnOverride() = m)
        )
    )
select p