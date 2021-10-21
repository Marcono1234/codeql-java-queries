/**
 * Finds calls to the splitting methods `String.split` and `Pattern.split` with
 * a split limit of 1. The result of such call is an array of length 1 containing
 * the argument to split, therefore having no effect.
 */

import java

class SplitMethod extends Method {
    SplitMethod() {
        getDeclaringType() instanceof TypeString
        and hasStringSignature("split(String, int)")
        or
        getDeclaringType().hasQualifiedName("java.util.regex", "Pattern")
        and hasStringSignature("split(CharSequence, int)")
    }

    int getSplitLimitParamIndex() {
        result = 1
    }
}

from MethodAccess splitCall, SplitMethod splitMethod, IntegerLiteral limit
where
    splitCall.getMethod() = splitMethod
    and splitCall.getArgument(splitMethod.getSplitLimitParamIndex()) = limit
    and limit.getIntValue() = 1
select splitCall, "Splitting with limit of 1 has no effect"
