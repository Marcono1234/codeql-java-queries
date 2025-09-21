/**
 * Finds `try` statements which directly contain an `if` statement which guards the actual code which
 * can throw the exception the `try` is supposed to catch.
 * For example:
 * ```java
 * try {
 *   if (condition) {
 *     doFallibleAction()
 *   }
 * } catch (Exception e) {
 *   ...
 * }
 * ```
 *
 * It might increase readibility to move the `if` statement outside the `try`:
 * ```java
 * if (condition) {
 *   try {
 *     doFallibleAction()
 *   } catch (Exception e) {
 *     ...
 *   }
 * }
 * ```
 *
 * @kind problem
 * @id todo
 */

// Note: This is a more general (and less precise) variant of `recommendations/resource-used-conditionally.ql`
import java

class ExprWithSideEffects extends Expr {
  ExprWithSideEffects() {
    this instanceof VarWrite or
    this instanceof Call
  }
}

from TryStmt tryStmt, IfStmt ifStmt
where
  tryStmt.getBlock().(SingletonBlock).getStmt() = ifStmt and
  // Ignore if there is a `finally` block which should always run, regardless of condition
  not exists(tryStmt.getFinally()) and
  not ifStmt.getCondition().getAChildExpr*() instanceof ExprWithSideEffects and
  // Ignore if condition uses resource created by `try` statement
  not ifStmt.getCondition().getAChildExpr*() =
    tryStmt.getAResourceDecl().getAVariable().getAnAccess() and
  // Ignore if there is an `else` block (which might also be fallible)
  not exists(ifStmt.getElse())
select ifStmt, "Should be moved outside $@", tryStmt, "enclosing try statement"
