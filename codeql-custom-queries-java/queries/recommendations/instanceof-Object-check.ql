/**
 * Finds `instanceof` expressions which check whether the operand is an
 * instance of `Object`. All objects are an instance of `Object` so this
 * test will only fail if the operand is `null`. To improve readability
 * an explicit `null` check in the form `!= null` should be preferred.
 */

import java

from InstanceOfExpr e
where e.getCheckedType() instanceof TypeObject
select e, "Should be replaced with an explicit null check"
