/**
 * Finds `assert` statements with `false` as constant expression. Such a statement
 * might be used for control flow branches which should never be reached. However,
 * when assertions are disabled and (due to a bug) such a branch is actually
 * reached the application might behave incorrectly. Therefore instead an
 * `AssertionError` should be explicitly thrown. E.g.:
 * ```java
 * if (alwaysTrue) {
 *     ...
 * } else {
 *     // Should instead do: throw new AssertionError(...);
 *     assert false;
 * }
 * ```
 */

// Real world example of this bug: https://bugs.openjdk.java.net/browse/JDK-8253459

import java

from AssertStmt assertStmt
where
    // Also consider compile time constants here
    assertStmt.getExpr().(CompileTimeConstantExpr).getBooleanValue() = false
    // Ignore test classes; `assert` in unit tests is detected by separate query
    and not assertStmt.getEnclosingCallable().getDeclaringType() instanceof TestClass
select assertStmt, "Should instead explicitly throw AssertionError"
