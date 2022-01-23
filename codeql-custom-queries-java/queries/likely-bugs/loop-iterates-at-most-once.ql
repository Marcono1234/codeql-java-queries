/**
 * Finds loop statements which iterate at most once. Such statements might
 * indicate a bug in the implementation. In case they behave as expected,
 * they should be replaced with an `if` statement to avoid confusion.
 * E.g.:
 * ```java
 * // Loop returns after first iteration; should be replaced with `if` statement
 * while (iterator.hasNext()) {
 *     return iterator.next();
 * }
 * ```
 */

import java
import lib.Loops

// Partially based on CodeQL's java/constant-loop-condition
private predicate iteratesAtMostOnce(LoopStmt loop) {
    exists (ControlFlowNode loopEntry |
        loopEntry = getLoopEntryNode(loop)
    |
        // Verify that loop has node in body, otherwise might match loop without body
        // or with empty body
        // Note: Might not be needed because apparently even empty body has node
        exists(getALoopIterationNode(loop))
        // None of the nodes in the loop body have the loopEntry as successor
        and not exists(ControlFlowNode node | node = getALoopIterationNode(loop) |
            node.getASuccessor() = loopEntry
        )
    )
}

from LoopStmt loop
where
    iteratesAtMostOnce(loop)
    // Enhanced `for` loop is sometimes used as shortcut for 'get first element of iterable, if present'
    // To reduce false positives ignore the loop unless it contains a nested loop
    and (loop instanceof EnhancedForStmt implies any(LoopStmt nestedLoop).getEnclosingStmt+() = loop.getBody())
select loop, "Loop iterates at most once"
