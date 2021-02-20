/**
 * Finds `toString()` implementations returning `null`. The documentation
 * of `Object.toString()` does not mention that it may return `null`; it
 * is therefore very likely that the caller is not expecting `null` which
 * could lead to a `NullPointerException` for the caller.
 */

import java

class ToStringMethod extends Method {
    ToStringMethod() {
        hasStringSignature("toString()")
    }
}

from ReturnStmt returnStmt
where
    returnStmt.getEnclosingCallable() instanceof ToStringMethod
    and returnStmt.getResult() instanceof NullLiteral
select returnStmt, "Returns null despite it not being allowed"
