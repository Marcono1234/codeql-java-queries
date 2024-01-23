/**
 * Finds calls to formatting methods such as `String.format` where the format string
 * is created using String concatenation. This can be inefficient (for example for
 * loggers where depending on the log level the formatted message is not needed),
 * and can lead to exceptions if the format string created this way contains accidental
 * format placeholders.
 *
 * For example:
 * ```java
 * // Error-prone: Can fail if `arg1` contains `%`
 * String.format("first: " + arg1 + ", second: %s", arg2)
 *
 * // Should be rewritten to
 * String.format("first: %s, second: %s", arg1, arg2)
 * ```
 *
 * @kind problem
 */

import java
import semmle.code.java.StringFormat
import semmle.code.java.dataflow.DataFlow

predicate isConstantString(Expr e) {
  e.(CompileTimeConstantExpr).getType() instanceof TypeString
  or
  // Or number expression which is for example used as 'width' in the format string,
  // e.g. `"%0" + width + "d"`
  e.getType() instanceof NumericType
  or
  // Or expression as a whole is not a constant, but its operands are
  isConstantString(e.(AddExpr).getLeftOperand()) and
  isConstantString(e.(AddExpr).getRightOperand())
  or
  isConstantString(e.(ConditionalExpr).getTrueExpr()) and
  isConstantString(e.(ConditionalExpr).getFalseExpr())
}

from FormattingCall formatCall, AddExpr formatStringExpr
where
  // Format string is created using String concat
  DataFlow::localExprFlow(formatStringExpr, formatCall.getFormatArgument()) and
  // Ignore if format string is constant and likely won't cause illegal format exceptions
  not isConstantString(formatStringExpr)
select formatStringExpr, "Format string created using String concatenation, used by $@", formatCall,
  "this formatting call"
