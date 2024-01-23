/**
 * Finds formatting calls without arguments, such as `String.format("some message")`.
 *
 * This is not only redundant and can be simplified (for `PrintStream` and `PrintWriter`
 * instead of `printf` `print` can be used), but can also cause an `IllegalFormatException`
 * if the string happens to contain a malformed `%`. If the string can be influenced
 * by an untrusted user, this could also be exploited for a denial-of-service attack.
 *
 * @kind problem
 */

import java

predicate containsLineSeparator(Expr e) {
  exists(e.(CompileTimeConstantExpr).getStringValue().indexOf("%n"))
  or
  // Or String concat where one operand contains "%n" (but the whole expression is not a constant)
  e.getType() instanceof TypeString and containsLineSeparator(e.(AddExpr).getAnOperand())
}

from MethodAccess call, Method m
where
  m = call.getMethod() and
  (
    m.getDeclaringType() instanceof TypeString and
    m.hasName(["format", "formatted"])
    or
    m.getDeclaringType()
        .getASourceSupertype*()
        .hasQualifiedName("java.io", ["PrintStream", "PrintWriter"]) and
    m.hasName(["format", "printf"])
    // Don't consider java.io.Console methods because there seems to be no direct alternative for writing
    // a non-formatted string
    // Don't consider java.util.Formatter because if only Formatter is available, using `formatter.out()` and
    // writing to that is more cumbersome and possibly not as easy to understand
  ) and
  // And no varargs arguments have been provided
  call.getNumArgument() < m.getNumberOfParameters() and
  // And does not use `%n` in format string to get OS-dependent line separator
  not containsLineSeparator(call.getAnArgument()) and
  // Also cover `String.formatted` where the qualifier is the format string
  not containsLineSeparator(call.getQualifier())
select call, "Formatting call without arguments can be simplified"
