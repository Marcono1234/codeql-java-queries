/**
 * Finds arguments of type `java.lang.Thread` passed as `Runnable` to
 * a `Thread` constructor:
 * ```
 * class WorkerThread extends Thread {
 *     public void run() {
 *         ...
 *     }
 * }
 *
 * // Uses WorkerThread as Runnable instead of directly starting it
 * Thread t = new Thread(new WorkerThread());
 * t.start();
 * ```
 *
 * Despite `Thread` implementing the `Runnable` interface, it should not
 * be used as argument when constructing another `Thread`. This is highly
 * misleading and often unintended.
 * Instead either the `Thread` object should be used as is (instead of
 * wrapping it inside another `Thread` object), or that object should not
 * be of type `Thread` but only implement the `Runnable` interface, e.g.:
 * ```
 * class WorkerThread extends Thread {
 *     public void run() {
 *         ...
 *     }
 * }
 *
 * Thread t = new WorkerThread();
 * t.start();
 * ```
 * or
 * ```
 * class WorkTask implements Runnable {
 *     public void run() {
 *         ...
 *     }
 * }
 *
 * Thread t = new Thread(new WorkTask());
 * t.start();
 * ```
 */

import java

class TypeThread extends Class {
    TypeThread() {
        getASourceSupertype().hasQualifiedName("java.lang", "Thread")
    }
}

class TypeRunnable extends Interface {
    TypeRunnable() {
        hasQualifiedName("java.lang", "Runnable")
    }
}

from ClassInstanceExpr newExpr, Expr threadArg, int argIndex
where
    newExpr.getConstructedType() instanceof TypeThread
    and threadArg.getType() instanceof TypeThread
    and newExpr.getArgument(argIndex) = threadArg
    and newExpr.getConstructor().getParameter(argIndex).getType() instanceof TypeRunnable
select threadArg, "Thread as Runnable argument for Thread constructor."
