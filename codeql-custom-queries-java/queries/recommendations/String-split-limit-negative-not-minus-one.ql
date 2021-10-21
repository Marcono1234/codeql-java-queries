/**
 * Finds calls to the splitting methods `String.split` and `Pattern.split` with
 * a negative split limit which is not -1. All negative split limit values have
 * the same effect, however to avoid any confusion it might be best to use -1 which
 * often has a special meaning for multiple methods. Using a different negative
 * limit might confuse the reader.
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

from MethodAccess splitCall, SplitMethod splitMethod, IntegerLiteral limit, int limitValue
where
    splitCall.getMethod() = splitMethod
    and splitCall.getArgument(splitMethod.getSplitLimitParamIndex()) = limit
    and limitValue = limit.getIntValue()
    and limitValue < -1
select splitCall, "Unconventional negative split limit " + limitValue
