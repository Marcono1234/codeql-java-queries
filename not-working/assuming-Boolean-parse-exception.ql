/**
 * Finds calls to one of the parsing methods or the constructor of `java.lang.Boolean` where
 * the caller assumes that an exception is thrown if parsing fails.
 * However, this assumption is wrong because these parsing methods never throw an exception,
 * but instead return `false`, even if `null` is provided as argument.
 */

import java

class BooleanParseCall extends Call {
    BooleanParseCall() {
        getCallee().getDeclaringType().hasQualifiedName("java.lang", "Boolean")
        and (
            this.(ClassInstanceExpr).getConstructor().hasStringSignature("Boolean(String)")
            or this.(MethodAccess).getMethod().getStringSignature() in ["parseBoolean(String)", "valueOf(String)"]
        )
    }
}

predicate encloses(Stmt s, Stmt enclosing) {
    s.getEnclosingStmt() = enclosing
    or encloses(s.getEnclosingStmt(), enclosing)
}

from BooleanParseCall parseCall, TryStmt tryStmt
where
    /*
     * TODO: Causes too many false positives
     * Should only consider directly enclosing try block and
     * should make sure that caught exception is not thrown by other expression,
     * e.g. argument of parsing call
     */
    encloses(parseCall.getEnclosingStmt(), tryStmt.getBlock())
select parseCall
