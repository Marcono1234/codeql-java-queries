/**
 * Finds `long` literals with a lowercase `L`, e.g. `5l`.
 * An uppercase `L` should be preferred, quoting the JLS:
 * > The suffix `L` is preferred, because the letter `l` (ell)
 * > is often hard to distinguish from the digit `1` (one).
 * [JLS 14 §3.10.1](https://docs.oracle.com/javase/specs/jls/se14/html/jls-3.html#jls-3.10.1)
 */

import java

from LongLiteral long, string literal
where
    literal = long.getLiteral()
    and literal.charAt(literal.length() - 1).isLowercase()
select long
