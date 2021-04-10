/**
 * Finds types which are declared in the `package-info.java` file of a
 * package. While this is permitted by Java, it should be avoided because
 * it will be confusing to contributors of the project and might also
 * not be supported by all IDEs.
 */

import java

from ClassOrInterface c
where
    c.fromSource()
    and c.getCompilationUnit().hasName("package-info")
select c, "Type is declared in package-info.java"
