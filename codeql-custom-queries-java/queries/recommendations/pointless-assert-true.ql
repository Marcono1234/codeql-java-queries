/**
 * Finds `assert` statements with a literal `true` as expression.
 * Such an assertion is pointless and should be removed. If the
 * `assert` is used to indicate that a control flow branch should
 * do nothing, it is better to instead add an explanatory comment.
 */

import java

from AssertStmt assertStmt
where
    // Only consider literals, but not compile time constants since they might come
    // from class of external dependency
    assertStmt.getExpr().(BooleanLiteral).getBooleanValue() = true
    // Ignore test classes; `assert` in unit tests is detected by separate query
    and not assertStmt.getEnclosingCallable().getDeclaringType() instanceof TestClass
select assertStmt, "Pointless assert statement"
