/**
 * Finds usage of a `long` literal as shift distance of a bitwise shift operation.
 * The type of the shift distance has no effect on the result of the expression,
 * therefore an integer literal should be used to avoid any confusion.
 * 
 * See [JLS 17 §15.19](https://docs.oracle.com/javase/specs/jls/se17/html/jls-15.html#jls-15.19).
 */

import java
import lib.Operations

from Shift s, LongLiteral l
where s.getShiftDistance() = l
select l, "Should be changed to an integer literal"
