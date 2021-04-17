/**
 * Finds calls to methods performing `null` checks where the argument is of
 * a primitive type. Because the primitive value will be wrapped in the boxed
 * type, it will never be `null`, so any `null` checks are pointless.
 */

import java
import lib.Nullness

from MethodAccess nullnessCheck, NullnessCheckingMethod nullnessCheckingMethod, Expr primitiveArg
where
    nullnessCheck.getMethod().getSourceDeclaration().getASourceOverriddenMethod*() = nullnessCheckingMethod
    and primitiveArg = nullnessCheck.getArgument(nullnessCheckingMethod.getNullCheckedParamIndex())
    and primitiveArg.getType() instanceof PrimitiveType
select nullnessCheck, "Performs nullness check on $@ expression of primitive type", primitiveArg, "this"
