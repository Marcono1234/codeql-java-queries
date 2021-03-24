/**
 * Finds conditional expressions (` ? : `) which check whether an optional instance,
 * such as `java.util.Optional`, has a value and then call the method for retrieving
 * the value. Optional types usually provide a method which accepts a supplier,
 * a call to such a method might be more concise. If the alternative expression is not
 * expensive (e.g. just a field read), then an optional method directly taking the
 * alternative argument could be called as well. E.g.:
 * ```java
 * // Could instead use: optional.orElseGet(Collections::emptyList);
 * // Or: optional.orElse(Collections.emptyList())
 * List<String> strings = optional.ifPresent() ? optional.get() : Collections.emptyList();
 * ```
 */

import java
import lib.Optionals
import lib.VarAccess

from ConditionalExpr conditionalExpr, MethodAccess presenceCheck, OptionalPresenceCheckMethod presenceCheckMethod, MethodAccess getValueCall, string alternative
where
    presenceCheck = conditionalExpr.getCondition()
    and presenceCheckMethod = presenceCheck.getMethod()
    // And get value call is guarded by presence check
    and getValueCall = conditionalExpr.getBranchExpr(presenceCheckMethod.polarity())
    and getValueCall.getMethod() instanceof OptionalGetValueMethod
    // And make sure calls occur on same variable
    and accessSameVarOfSameOwner(presenceCheck.getQualifier(), getValueCall.getQualifier())
    // Conditional expression does not eagerly evaluate both branches; therefore can only suggest
    // supplier as alternative
    and alternative = presenceCheckMethod.getOptionalType().getSupplierAlternativeName()
select conditionalExpr, "Could use " + alternative + " instead"
