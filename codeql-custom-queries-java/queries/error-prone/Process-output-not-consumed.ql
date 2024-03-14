/**
 * Finds creation of a `Process` whose std-out and std-err output is not consumed.
 * Operating systems often only have a limited output buffer for these outputs, so when the
 * output is not consumed, these buffers become full and the process could hang because it
 * cannot write any further output. This can even lead to a deadlock when `Process.waitFor`
 * is used, because it waits for the process to finish and the process waits for the Java
 * program to consume the output.
 *
 * The proper way to consume the output is by:
 * - Using `ProcessBuilder.inheritIO()`
 * - Or using both `ProcessBuilder.redirectOutput` and `ProcessBuilder.redirectError` with something
 *   other than `Redirect.PIPE`
 * - Or reading from the `Process` `errorReader()` / `getErrorStream()` and `inputReader()` / `getInputStream()`\
 *   Important:
 *    - Both std-out _and_ std-err must be consumed
 *    - Output processing must start asynchronously _before_ `Process.waitFor` (or similar) is called
 *    - std-out and std-err must be processed concurrently; consuming them in the same thread sequentially
 *      could still lead to a deadlock since these streams normally only end when the process has terminated
 *    - If a program is only interested in some part of the std-out and std-err output, it must still
 *      continue reading it afterwards, even if it just discards the read data
 *
 * @id todo
 * @kind problem
 */

import java
import semmle.code.java.dataflow.DataFlow

// Note: This does not cover all cases where the Process output is not properly consumed, but it covers at least
// the most obvious cases

/**
 * Gets an expression which creates a `Process` whose output is not redirected.
 */
Expr processWithoutRedirect() {
  // Call of `Runtime.exec`
  exists(Method execMethod |
    execMethod.getDeclaringType() instanceof TypeRuntime and
    execMethod.hasName("exec") and
    result.(MethodAccess).getMethod() = execMethod
  )
  or
  // Creation of `ProcessBuilder` followed by `ProcessBuilder.start()`
  exists(ClassInstanceExpr newProcessBuilder, MethodAccess startCall |
    newProcessBuilder.getConstructedType() instanceof TypeProcessBuilder and
    startCall.getMethod().hasStringSignature("start()") and
    // TODO Have to model value steps for ProcessBuilder methods to support chaining of builder calls?
    DataFlow::localExprFlow(newProcessBuilder, startCall.getQualifier()) and
    // And there is no usage of ProcessBuilder method which redirects streams
    not exists(MethodAccess redirectCall, Method redirectMethod |
      DataFlow::localExprFlow(newProcessBuilder, redirectCall.getQualifier()) and
      redirectCall.getMethod() = redirectMethod and
      (
        redirectMethod.hasName("inheritIO")
        or
        /* TODO: Maybe should consider whether both `redirectError` and `redirectOutput` are used? (and not just one of them) */
        // Don't consider `redirectErrorStream(boolean)`; it would still be necessary to read the combined output stream then
        redirectMethod.hasName(["redirectError", "redirectOutput"]) and
        redirectMethod.getNumberOfParameters() = 1 and
        // And not using `Redirect.PIPE`
        not exists(Field redirectPipe |
          redirectCall.getArgument(0).(FieldRead).getField() = redirectPipe and
          redirectPipe.getDeclaringType().hasQualifiedName("java.lang", "ProcessBuilder$Redirect") and
          redirectPipe.hasName("PIPE")
        )
      )
    ) and
    result = startCall
  )
}

Expr getAnEnclosingExpr(Expr e) {
  result = e.getParent*()
  or
  // Or anonymous class (or lambda) which contains expression
  result =
    getAnEnclosingExpr(e.getEnclosingCallable()
          .getDeclaringType()
          .(AnonymousClass)
          .getClassInstanceExpr())
}

from Expr processCreation, MethodAccess waitForProcess
where
  processCreation = processWithoutRedirect() and
  waitForProcess
      .getMethod()
      .hasName([
          "waitFor",
          // Also cover `onExit` assuming that caller might wait on it soon afterwards (before obtaining output streams)
          "onExit"
        ]) and
  DataFlow::localExprFlow(processCreation, waitForProcess.getQualifier()) and
  // And no output stream method is called before waiting
  not exists(MethodAccess outputAccess |
    outputAccess
        .getMethod()
        .hasName(["errorReader", "getErrorStream", "inputReader", "getInputStream",])
  |
    // Output access before `waitFor` call
    DataFlow::localExprFlow(processCreation, outputAccess.getQualifier()) and
    DataFlow::localExprFlow(outputAccess.getQualifier(), waitForProcess.getQualifier())
    or
    // Or output access in anonymous class or lambda before `waitFor` call, by accessing Process stored in variable
    // (assuming that this anonymous class or lambda is used as concurrent task)
    exists(Variable var, Expr assignedValue, Expr outputAccessEnclosing |
      assignedValue = var.getAnAssignedValue() and
      // Make sure the order is correct (and the dataflow is for the same value): processCreation -> varAssign -> waitFor
      DataFlow::localExprFlow(processCreation, assignedValue) and
      DataFlow::localExprFlow(assignedValue, waitForProcess.getQualifier()) and
      outputAccess.getQualifier() = var.getAnAccess() and
      outputAccessEnclosing = getAnEnclosingExpr(outputAccess) and
      // Make sure the order is correct: processCreation -> outputAccess -> waitFor
      // Otherwise this could lead to false negatives when a variable is reused
      processCreation.getControlFlowNode().getASuccessor*() = outputAccessEnclosing and
      outputAccessEnclosing.getControlFlowNode().getASuccessor*() = waitForProcess
    )
  )
select waitForProcess, "Waits for process without consuming its output"
