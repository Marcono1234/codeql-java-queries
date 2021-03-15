/**
 * Finds methods which override `java.lang.Appendable.append(...)`,
 * but do not return `this`.
 * This issue often occurs when a class delegates appending to another
 * Appendable (e.g. a Writer) and then erroneously returns the result of
 * that delegate call.
 */

import java

class AppendMethod extends Method {
    AppendMethod() {
        getDeclaringType().hasQualifiedName("java.lang", "Appendable")
        and (
            hasStringSignature("append(char)")
            or hasStringSignature("append(CharSequence)")
            or hasStringSignature("append(CharSequence, int, int)")
        )
    }
}

from ReturnStmt return
where
    return.getEnclosingCallable().(Method).getAnOverride() instanceof AppendMethod
    // Not returning `this`
    and not exists (ThisAccess thisAccess |
        thisAccess = return.getResult()
        // `this` should refer to own instance
        and thisAccess.isOwnInstanceAccess()
    )
    // And not returning result of delegate call, e.g. `return append(csq, 0, csq.length())`
    and not exists (MethodAccess delegateCall |
        delegateCall.getMethod().getAnOverride*() instanceof AppendMethod
        and delegateCall.isOwnMethodAccess()
        and delegateCall = return.getResult()
    )
select return
