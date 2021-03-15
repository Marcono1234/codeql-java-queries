/**
 * Finds variables and fields whose names starts with an upper-case letter.
 * By convention the name should start with a lower-case letter (unless the
 * variable is a constant) because it could otherwise be confused with a type
 * name when skimming the code.
 *
 * See also https://docs.oracle.com/javase/specs/jls/se14/html/jls-6.html#jls-6.1
 * (sections "Field Names" and "Local Variable and Parameter Names")
 */

import java

from Variable var
where
    var.getName().regexpMatch("\\p{Upper}.*")
    // Ignore if variable is intended as constant
    and not (
        (var.isFinal() or var.(Field).isStatic())
        and not var.getName().regexpMatch("\\p{Lower}.*")
    )
select var
