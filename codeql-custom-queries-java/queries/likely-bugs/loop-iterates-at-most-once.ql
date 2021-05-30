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

// Partially based on CodeQL's java/constant-loop-condition
Expr getLoopEntry(LoopStmt loop) {
    result = loop.(EnhancedForStmt).getVariable()
    or if exists(loop.(ForStmt).getAnUpdate())
    then result = loop.(ForStmt).getUpdate(0)
    // Note: For do-while loop condition is not really the entry, but it
    // works here regardless
    else result = loop.getCondition()
}

// Partially based on CodeQL's java/constant-loop-condition
private predicate iteratesAtMostOnce(LoopStmt loop) {
    exists (Expr loopReentry |
        loopReentry = getLoopEntry(loop)
    |
        // Verify that loop has node in body, otherwise might match loop without body
        // or with empty body
        // Note: Might not be needed because apparently even empty body has node
        exists(ControlFlowNode node | node.getEnclosingStmt().getEnclosingStmt*() = loop.getBody())
        // None of the nodes in the loop body have the loopReentry as successor
        /*
         * TODO: This can have false negatives for nested loops where the loop entry of the inner loop
         * is reached due to the subsequent iteration of the outer loop
         */
        and not exists(ControlFlowNode loopNode |
            loopNode.getEnclosingStmt().getEnclosingStmt*() = loop.getBody()
            and loopNode.getASuccessor+() = loopReentry.getControlFlowNode()
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
