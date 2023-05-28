/**
 * Finds `throw` statements which throw the `null` literal, i.e. `throw null;`.
 * While this does produce a `NullPointerException` (as probably desired)
 * it is rather obscure and misuses the `null` check of the `throw` statement.
 * For clarity it would be better to explicitly create a `NullPointerException`
 * and possibly provide a meaningful message to its constructor.
 * 
 * The "helpful `NullPointerException`" feature ([JEP-358](https://openjdk.org/jeps/358))
 * makes it even clearer that `throw null` is not the intended usage:
 * > NullPointerException: Cannot throw exception because "null" is null
 * 
 * See also Error Prone pattern [ThrowNull](https://errorprone.info/bugpattern/ThrowNull).
 * 
 * @kind problem
 */

import java

from ThrowStmt throwStmt
where
    throwStmt.getExpr() instanceof NullLiteral
select throwStmt, "Should use `throw new NullPointerException(...)` instead"
