/**
 * Finds `throw` statements which throw the `null` literal, i.e. `throw null;`.
 * While this does produce a NullPointerException (as probably desired)
 * it is rather obscure and misuses the `null` check of the `throw` statement.
 * For clarity it would be better to explicitly create a NullPointerException
 * and possibly provide a meaningful message to its constructor.
 */

import java

from ThrowStmt throwStmt
where
    throwStmt.getExpr() instanceof NullLiteral
select throwStmt
