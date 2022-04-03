/**
 * Finds enum or record classes which implement `java.io.Externalizable`. The serialization format
 * of these classes cannot be customized, so implementing `Externalizable` is pointless.
 */

import java

import lib.JavaSerialization

from Class c
where
    c.fromSource()
    and (
        // Enum type, but not anonymous subclass (to avoid duplicate results)
        c instanceof EnumType and not c instanceof AnonymousClass
        or c instanceof Record
    )
    and c.getASourceSupertype+() instanceof TypeExternalizable
select c, "Implementing Externalizable has no effect on serialization"
