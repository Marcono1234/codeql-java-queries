/**
 * Finds code which uses a `Thread` as `Runnable`. The class `Thread` implements `Runnable`,
 * but the actual scheduling of the thread is done by the `start()` method. Therefore
 * using a `Thread` where a `Runnable` is expected most likely provides no advantage and
 * only leads to confusion.
 *
 * For example:
 * ```java
 * executor.execute(new Thread(...));
 * ```
 * Should be replaced with:
 * ```java
 * executor.execute(new MyRunnable(...));
 * ```
 *
 * @kind problem
 * @id todo
 */

// Note: This is a more generic variant of `likely-bugs/Thread-as-Runnable-argument-for-Thread-constructor.ql`
import java
import semmle.code.java.Conversions

class TypeThread extends Class {
  TypeThread() { hasQualifiedName("java.lang", "Thread") }
}

class TypeRunnable extends Interface {
  TypeRunnable() { hasQualifiedName("java.lang", "Runnable") }
}

from ConversionSite threadConversion
where
  // Source is of type Thread (or subtype)
  threadConversion.getConversionSource().(RefType).getASourceSupertype*() instanceof TypeThread and
  // Target is of type Runnable (or subtype, which is not Thread)
  threadConversion.getConversionTarget().(RefType).getASourceSupertype*() instanceof TypeRunnable and
  not threadConversion.getConversionTarget().(RefType).getASourceSupertype*() instanceof TypeThread
select threadConversion, "Thread used as Runnable"
