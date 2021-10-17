/**
 * Finds minus signs in front of `int` and `long` literals with value 0,
 * for example `-0`. The minus sign has no effect because these data types
 * do not have a negative 0 (unlike floating point types). Even if the
 * value is then converted to a floating point type, the minus sign has
 * no effect, the resulting value will be `+0`.
 */

import java
import lib.Literals

from MinusExpr e
where e.getExpr() instanceof LiteralIntegralZero
select e, "Minus sign has no effect"
