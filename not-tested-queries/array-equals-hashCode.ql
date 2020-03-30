/**
 * Finds calls to `equals` or `hashCode` of an array. Arrays don't override
 * these methods so they test for reference equality. This is likely not the
 * desired behavior of the caller.
 */

import java

from MethodAccess call, Method m
where
    m = call.getMethod()
    and (m instanceof EqualsMethod or m instanceof HashCodeMethod)
    and call.getQualifier().getType() instanceof Array
select call
