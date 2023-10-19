/**
 * Finds usage of the object monitor lock for types implementing the `Condition`
 * or `Lock` interface. The object monitor lock is used by the `synchronized (...)`
 * statement and when calling the `Object` methods `notify`, `notifyAll` and `wait`.
 * Doing this on a `Condition` or `Lock` will most likely not work as desired
 * because those types might not be implemented using the object monitor lock.
 * Instead their dedicated methods should be used, such as `Condition.await()` or
 * `Lock.lock()`.
 *
 * This query is similar to the following SpotBug patterns:
 * - [DM_MONITOR_WAIT_ON_CONDITION](https://spotbugs.readthedocs.io/en/stable/bugDescriptions.html#dm-monitor-wait-called-on-condition-dm-monitor-wait-on-condition)
 * - [JML_JSR166_CALLING_WAIT_RATHER_THAN_AWAIT](https://spotbugs.readthedocs.io/en/stable/bugDescriptions.html#jlm-using-monitor-style-wait-methods-on-util-concurrent-abstraction-jml-jsr166-calling-wait-rather-than-await)
 * - [JLM_JSR166_LOCK_MONITORENTER](https://spotbugs.readthedocs.io/en/stable/bugDescriptions.html#jlm-synchronization-performed-on-lock-jlm-jsr166-lock-monitorenter)
 *
 * @kind problem
 */

// This extends CodeQL's query `java/wait-on-condition-interface`

import java

from Expr expr
where
  expr.getType()
      .(RefType)
      .getASourceSupertype*()
      .hasQualifiedName("java.util.concurrent.locks", ["Condition", "Lock"]) and
  (
    any(SynchronizedStmt s).getExpr() = expr
    or
    exists(MethodAccess call, Method m |
      call.getQualifier() = expr and
      m = call.getMethod() and
      m.getDeclaringType() instanceof TypeObject and
      m.hasName(["notify", "notifyAll", "wait"])
    )
  )
  // Ignore if Condition or Lock implementation internally uses object monitor lock
  and not expr instanceof ThisAccess
select expr, "Uses object monitor lock of " + expr.getType().getName()
