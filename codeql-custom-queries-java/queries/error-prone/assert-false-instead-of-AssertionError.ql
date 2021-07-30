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
 * 
 * However, an `AssertionError` might propagate high up the call stack before
 * it is handled. Applications where it might be possible for an adversary to
 * trigger this unexpected condition might want to prefer throwing a
 * `RuntimeException` or a subclass of it to prevent any denial of service
 * attacks.
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
