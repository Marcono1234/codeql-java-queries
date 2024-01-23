/**
 * Finds calls which format a string, for example using `String.format`, but where
 * the format pattern string also comes from a formatted string. Such code is not only
 * potentially redundant, but it can also lead to exceptions if the first format call
 * accidentally adds `%`, which is interpreted as placeholder by the second format call.
 *
 * For example:
 * ```java
 * void checkArgument(boolean arg, String message, Object... messageArgs) {
 *     if (!arg) {
 *         throw new IllegalArgumentException(String.format(message, messageArgs));
 *     }
 * }
 *
 * ...
 *
 * // Bug: `checkArgument` will also call `String.format`
 * // Fails for example if `value = "some%text"`
 * checkArgument(isValid, String.format("invalid value: %s", value));
 * ```
 *
 * @id todo
 * @kind problem
 */

import java
import semmle.code.java.StringFormat
import semmle.code.java.dataflow.TaintTracking

from
  FormattingCall firstFormatCall, FormattingCall secondFormatCall, Expr secondFormatString,
  string message, FormattingCall argExpr, string argMessage
where
  // Only consider `Formatter` formatting, don't consider mixed formatting variants,
  // e.g. `logger.error(String.format(...))` since logger might not support rich formatting
  not firstFormatCall.getSyntax().isLogger() and
  not secondFormatCall.getSyntax().isLogger() and
  secondFormatString = secondFormatCall.getFormatArgument() and
  TaintTracking::localExprTaint(firstFormatCall, secondFormatString) and
  // Ignore if first format call seems to use integer args to create the format layout for the second
  // call, e.g. if `firstFormatCall` is `String.format("%%%ds", count)` (used by netty/netty in a test)
  not forex(Expr arg | arg = firstFormatCall.getAnArgumentToBeFormatted() |
    arg.getType().(NumericType).hasName(["int", "Integer"])
  ) and
  if secondFormatString = firstFormatCall
  then (
    message = "Formatting here is redundant because $@ performs formatting itself" and
    argExpr = secondFormatCall and
    argMessage = "the called method"
  ) else (
    message = "This format string argument has already been formatted $@ before" and
    argExpr = firstFormatCall and
    argMessage = "here"
  )
select secondFormatString, message, argExpr, argMessage
