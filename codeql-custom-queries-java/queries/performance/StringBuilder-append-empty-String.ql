/**
 * Finds `append(...)` calls on a `StringBuilder` or `StringBuffer` where the argument
 * is an empty String. Such as call has no effect and should be removed.
 */

import java

// TODO: Reduce code duplication; already declared in manual-CharSequence-joining.ql
class StringAppendingMethod extends Method {
    StringAppendingMethod() {
        (
            getDeclaringType() instanceof TypeStringBuilder
            or getDeclaringType() instanceof TypeStringBuffer
        )
        and hasName("append")
    }
}

from MethodAccess appendCall
where
    appendCall.getMethod() instanceof StringAppendingMethod
    and appendCall.getAnArgument().(StringLiteral).getRepresentedString() = ""
select appendCall, "Appends empty String"
