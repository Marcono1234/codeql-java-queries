/**
 * Finds top-level types whose name does not match the name of their
 * compilation unit. E.g.: `class OtherClass { }` being declared in `MyClass.java`.
 */

import java

from TopLevelType c, CompilationUnit file
where
    file.fromSource()
    and c.getCompilationUnit() = file
    // Ignore types declared in `package-info.java`
    and not file.hasName("package-info")
    and c.getName() != file.getName()
    // And there is not another type in the compilation unit, then for one of
    // the types there must be a name mismatch; additionally multiple top-level
    // types in one compilation unit should be detected by separate query
    and not exists(TopLevelType other |
        other != c
        and other.getCompilationUnit() = file
    )
select c, "Is in '" + file.getBaseName() + "' but should be in '" + c.getName() + ".java'"
