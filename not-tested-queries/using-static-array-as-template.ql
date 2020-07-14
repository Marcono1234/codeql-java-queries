/**
 * Finds static arrays which appear to be used as template for an argument, e.g.:
 * ```
 * class EchoPrinter {
 *     static final String[] COMMAND = {"echo", NULL};
 *
 *     public static void echo(String text) {
 *         // Modifies static array without synchronization; concurrent use would
 *         // lead to unpredictable behavior
 *         COMMAND[1] = text;
 *         new ProcessBuilder(COMMAND).start();
 *     }
 * }
 * ```
 *
 * If used without synchronization, the behavior becomes unpredictable in case
 * the method is used concurrently because one thread could overwrite the value
 * another thread just set.
 * Often it is most appropriate to simply create a new array every time instead
 * of trying to reuse an existing one.
 */

import java

class StaticArray extends Field {
    StaticArray() {
        isStatic()
        and getType() instanceof Array
    }
}

from StaticArray array, Callable enclosingCallable, Assignment assignment, Call call
where
    assignment.getDest().(ArrayAccess).getArray() = array.getAnAccess()
    and call.getAnArgument() = array.getAnAccess()
    and enclosingCallable = assignment.getEnclosingCallable()
    // Assignment in static initializer is safe
    and not enclosingCallable instanceof StaticInitializer
    // Ignore if callable is static and synchronized
    and not (
        enclosingCallable.isStatic()
        and enclosingCallable.isSynchronized()
    )
    and assignment.getControlFlowNode().getASuccessor+() = call
select assignment, call
