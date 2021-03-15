/**
 * Finds loop statements which iterate at most once. Such statements might
 * indicate a bug in the implementation. In case they behave as expected,
 * they should be replaced with an `if` statement to avoid confusion.
 * E.g.:
 * ```
 * // Loop returns after first iteration; should be replaced with `if` statement
 * while (iterator.hasNext()) {
 *     return iterator.next();
 * }
 * ```
 */

import java

// Partially based on CodeQL's java/constant-loop-condition
private predicate iteratesAtMostOnce(LoopStmt loop) {
    exists (Expr loopReentry |
        if exists(loop.(ForStmt).getAnUpdate())
        then loopReentry = loop.(ForStmt).getUpdate(0)
        else loopReentry = loop.getCondition()
    |
        // Verify that loop has node in body, otherwise might match loop without body
        // or with empty body
        // Note: Might not be needed because apparently even empty body has node
        exists(ControlFlowNode node | node.getEnclosingStmt().getEnclosingStmt*() = loop.getBody())
        // None of the nodes in the loop body have the loopReentry as successor 
        and not exists(ControlFlowNode loopNode |
            loopNode.getEnclosingStmt().getEnclosingStmt*() = loop.getBody()
            and loopNode.getASuccessor().(Expr).getParent*() = loopReentry
        )
    )
}

from LoopStmt loop
where iteratesAtMostOnce(loop)
select loop, "Loop iterates at most once"
