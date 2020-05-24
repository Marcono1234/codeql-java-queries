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
    and not exists (ThisAccess thisAccess |
        thisAccess = return.getResult()
        // `this` should be unqualified, otherwise it might return enclosing instance
        and not exists (thisAccess.getQualifier())
    )
select return
