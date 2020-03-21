/**
 * For efficiency `equals(Object)` implementations should start by
 * checking if `obj == this`.
 * This query finds implementations which do not do this.
 */

import java

from Method method
where
    method.hasStringSignature("equals(Object)")
    // Check that obj is not passed to other method, i.e. equality check is delegated
    and not exists(MethodAccess call | call.getAnArgument().(RValue).getVariable() = method.getAParameter())
    // Check if no equality check containing `this` and `obj` exists
    and not exists(EqualityTest eq |
        eq.getAnOperand().(RValue).getVariable() = method.getAParameter()
        and eq.getAnOperand() instanceof ThisAccess
    )
select method
