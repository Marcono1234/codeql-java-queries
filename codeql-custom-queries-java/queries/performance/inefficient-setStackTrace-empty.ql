/**
 * Finds calls like `exception.setStackTrace(new StackTraceElement[0])`.
 * If the intention is to disable capturing of stack traces, then this is likely not
 * as efficient as it could be because the JVM has already captured the stack trace
 * at this point. This applies even when `setStackTrace` is called within the
 * constructor, because the constructor of the superclass `Throwable` has
 * already called `fillInStackTrace()`.
 *
 * To efficiently disable the stack trace, use on of these approaches:
 * - Call the superclass constructor with `writableStackTrace` parameter set to `false`\
 *   (only possible when the direct superclass is `Throwable`, `Error`, `Exception`
 *   or `RuntimeException`)
 * - Override `fillInStackTrace`
 *
 * @kind problem
 * @id TODO
 */

import java

class MethodSetStackTrace extends Method {
  MethodSetStackTrace() {
    getDeclaringType() instanceof ThrowableType and
    hasStringSignature("setStackTrace(StackTraceElement[])")
  }
}

class MethodFillInStackTrace extends Method {
  MethodFillInStackTrace() {
    getDeclaringType() instanceof ThrowableType and
    hasStringSignature("fillInStackTrace()")
  }
}

class EmptyArray extends ArrayCreationExpr {
  EmptyArray() { getFirstDimensionSize() = 0 }
}

// Note: For now don't restrict matches to `setStackTrace` call in own constructor; while this
// does reduce false positives, it also hides true positives where the exception is created and
// immediately afterwards `setStackTrace` is called, and this is the only way instances of this
// type are created (or it might be possible to add a constructor with `writableStackTrace` parameter)
from MethodCall setStackTraceCall, Expr stackTraceArray
where
  setStackTraceCall.getMethod() instanceof MethodSetStackTrace and
  stackTraceArray = setStackTraceCall.getArgument(0) and
  (
    stackTraceArray instanceof EmptyArray
    or
    exists(Variable var |
      var = stackTraceArray.(VarRead).getVariable() and
      var.getInitializer() instanceof EmptyArray and
      forall(Expr varValue | varValue = var.getAnAssignedValue() | varValue instanceof EmptyArray)
    )
  ) and
  // Ensure that user can actually modify source of exception class to fix this issue
  setStackTraceCall.getReceiverType().fromSource() and
  // Ignore if `fillInStackTrace()` is overridden (and is calling `setStackTrace`)
  not (
    setStackTraceCall.isOwnMethodCall() and
    setStackTraceCall.getEnclosingCallable() instanceof MethodFillInStackTrace
  ) and
  not setStackTraceCall.getEnclosingCallable().getDeclaringType() instanceof TestClass
select setStackTraceCall, "Inefficient way to disable capturing of stack trace"
