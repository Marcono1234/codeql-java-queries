/**
 * Finds methods which look like a setter method taking a boolean parameter,
 * but which actually use `|= ` (OR) or `&=` (AND) to set the value.
 * Such methods can be misleading because they effectively ignore `false`
 * respectively `true` values.
 * For example:
 * ```java
 * public void setEnabled(boolean enabled) {
 *   this.enabled |= enabled;
 * }
 * ```
 * Without knowing how the method is implemented, a caller might assume that
 * `setEnabled(false)` disables the functionality. However, if `this.enabled`
 * is already `true`, then this call has no effect (because `true | false` is `true`).
 *
 * It might be less confusing if the `boolean` parameter was removed from the method:
 * ```java
 * public void setEnabled() {
 *   this.enabled = true;
 * }
 * ```
 * It is clear then that there is no way to 'disable' the functionality.
 *
 * @kind problem
 * @id todo
 */

import java

// TODO: Maybe also consider setters which use `||` or `&&`, or guard the assignment with an `if` statement
from Method setter, Parameter param, AssignOp assignExpr
where
  setter.getNumberOfParameters() = 1 and
  param = setter.getParameter(0) and
  param.getType() instanceof BooleanType and
  assignExpr = setter.getBody().(SingletonBlock).getStmt().(ExprStmt).getExpr() and
  assignExpr.getSource() = param.getAnAccess() and
  (assignExpr instanceof AssignOrExpr or assignExpr instanceof AssignAndExpr)
select setter, "Misleading boolean setter method"
