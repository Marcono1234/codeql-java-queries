/**
 * Finds type variables whose name contains a lower-case letter, e.g.:
 * ```
 * // `Argument` is the name of the type variable
 * class Container<Argument> {
 *     ...
 * }
 * ```
 *
 * By convention type variable names should not include lower-case
 * letters because the name could then be confused with a class name.
 *
 * See also https://docs.oracle.com/javase/specs/jls/se14/html/jls-6.html#jls-6.1
 * (section "Type Variable Names")
 */

import java

from TypeVariable typeVar
where
    typeVar.fromSource()
    // Ignore if name ends with "Type"
    and typeVar.getName().regexpMatch(".*\\p{Lower}.*(?<!Type)")
select typeVar
