/*
 * Finds equality test expressions which check whether `this` is `null`.
 * Because the `this` keyword can only be used in non-static contexts
 * it is always non-`null`.
 */

import java

from EqualityTest eqTest
where
    eqTest.getAnOperand() instanceof NullLiteral
    and eqTest.getAnOperand() instanceof ThisAccess
select eqTest
