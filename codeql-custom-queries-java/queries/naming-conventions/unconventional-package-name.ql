/**
 * Finds packages where one of its components starts with an upper-case letter.
 * By convention the component names should start with lower-case letters
 * because they could otherwise be confused with type names when skimming
 * the code.
 *
 * See also https://docs.oracle.com/javase/specs/jls/se14/html/jls-6.html#jls-6.1
 * (section "Package Names and Module Names")
 */

import java

from Package package
where
    package.fromSource()
    // Any component of the package name which starts with an upper-case letter
    // Can't use QL's isUppercase because it would match any non-lower-case
    // character, e.g. '_'
    and package.getName().splitAt(".").regexpMatch("\\p{Upper}.*")
select package
