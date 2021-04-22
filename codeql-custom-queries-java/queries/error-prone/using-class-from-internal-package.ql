/**
 * Finds usage of types which are declared in a package whose name
 * contains `internal`. Depending on internal packages of libraries
 * is error-prone because the library authors often make no guarantees
 * about the behavior of the internal types and might remove or change
 * them without any notice.
 */

import java

from TypeAccess typeAccess, RefType type
where
    type = typeAccess.getType().(RefType).getSourceDeclaration()
    // Ignore access of internal types within the project
    and not type.fromSource()
    // Containing `.internal.` or ending with `.internal`
    and type.getPackage().getName().regexpMatch(".*\\.internal(\\.|$)")
select typeAccess, "Accesses type " + type.getQualifiedName() + " from internal package"
