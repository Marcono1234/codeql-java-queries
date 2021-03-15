/**
 * Finds static imports (`import static`) for nested types.
 * In this case there is no difference between a static import and
 * a regular import so the regular import should be preferred.
 */

import java

from ImportStaticTypeMember staticImport
where
    exists (staticImport.getATypeImport())
    // Check that import does not additionally import field or method
    // (which is possible if they all have the same name)
    and not exists (staticImport.getAFieldImport())
    and not exists (staticImport.getAMethodImport())
select staticImport
