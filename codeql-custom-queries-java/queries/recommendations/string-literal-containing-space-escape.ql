/**
 * Finds usage of the `\s` escape sequence in regular string literals.
 * This escape sequence represents the space character ` ` (U+0020),
 * it was mainly added for text block support in Java 15 and is therefore
 * still relatively new. Additionally, other programming languages such
 * as C++, Python or JavaScript currently do not have this escape sequence,
 * and thus might not be familiar to all developers.
 * 
 * Therefore usage of `\s` in regular string literals should be avoided
 * and instead simply a regular space ` ` should be written.
 */

import java
import lib.Expressions

from StringLiteral l, string literal
where
    // Ignore text blocks, there usage of `\s` can make sense
    not l instanceof TextBlock
    and literal = l.getLiteral()
    and exists(literal.regexpFind("(?<!\\\\)(\\\\\\\\)*\\\\s", _, _))
select l, "Contains space escape sequence `\\s`"
