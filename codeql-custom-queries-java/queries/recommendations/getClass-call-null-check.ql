/**
 * Finds calls to `getClass()` which seem to be used as `null` check. In the past
 * code such as `variable.getClass();` was used to cause a `NullPointerException`
 * in case the variable is `null`. However, the intention of such code is not
 * directly obvious. Nowadays the method `Objects.requireNonNull` should be
 * preferred because it makes the intention clearer.
 * 
 * @kind problem
 */

// Related changes in JDK code: https://bugs.openjdk.org/browse/JDK-8073479

// Note: Unfortunately Objects.requireNonNull does not created helpful NullPointerExceptions yet,
// see https://bugs.openjdk.org/browse/JDK-8233268

import java

from MethodAccess getClassCall
where
    getClassCall.getMethod().hasStringSignature("getClass()")
    // And return value is ignored
    and getClassCall instanceof ValueDiscardingExpr
select getClassCall, "Should be replaced with `Objects.requireNonNull`"
