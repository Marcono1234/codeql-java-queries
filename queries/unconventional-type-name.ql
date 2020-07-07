/**
 * Finds classes and interfaces whose name starts with a lower-case letter
 * or whose name is a single upper-case letter.
 * By convention the name should start with an upper-case letter because it
 * could otherwise be confused with a field or variable name when skimming
 * the code. Names which are a single upper-case letter should be avoided as
 * well because they could be confused with type variable names.
 *
 * See also https://docs.oracle.com/javase/specs/jls/se14/html/jls-6.html#jls-6.1
 * (section "Class and Interface Type Names")
 */

import java

from ClassOrInterface type, string name
where
    type.fromSource()
    and name = type.getName()
    and (
        // Can't use QL's isLowercase because it would match any non-upper-case
        // character, e.g. '_'
        type.getName().regexpMatch("\\p{Lower}.*")
        // TODO: Ignore if single upper-case letter type is test-source
        // Only a single upper-case letter (could be confused with type variable)
        or type.getName().regexpMatch("\\p{Upper}")
    )
select type
