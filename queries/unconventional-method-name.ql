/**
 * Finds methods whose name starts with an upper-case letter.
 * By convention the name should start with a lower-case letter because it
 * could otherwise be confused with a type name when skimming the code.
 *
 * See also https://docs.oracle.com/javase/specs/jls/se14/html/jls-6.html#jls-6.1
 * (section "Method Names")
 */

import java

from Method method
where
    method.fromSource()
    // Can't use QL's isUppercase because it would match any non-lower-case
    // character, e.g. '_'
    and method.getName().regexpMatch("\\p{Upper}.*")
select method
