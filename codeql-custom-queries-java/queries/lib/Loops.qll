import java

/**
 * Gets the node representing the element which is executed first for every
 * loop iteration.
 */
ControlFlowNode getLoopEntryNode(LoopStmt loop) {
    result = loop.(EnhancedForStmt).getVariable().getControlFlowNode()
    // Note: Don't use getCondition().getControlFlowNode() because for nested conditions this would be the
    // last node of the condition
    or result = loop.(WhileStmt).getControlFlowNode().getANormalSuccessor() // successor is loop condition
    // For do-while condition is at the end of the iteration, therefore use node of its body
    or result = loop.(DoStmt).getStmt().getControlFlowNode()
    or exists(ForStmt forStmt | forStmt = loop |
        // Either get successor of init or successor of statement itself, which is its body
        if exists(forStmt.getAnInit()) then exists(Expr lastInit |
            lastInit = forStmt.getInit(count(forStmt.getAnInit()) - 1)
            // Successor of last init is first node of condition of loop
            and result = lastInit.getControlFlowNode().getANormalSuccessor()
        )
        // Successor is first node of loop condition, or body if no condition is present
        else result = forStmt.getControlFlowNode().getANormalSuccessor()
    )
}

/**
 * Gets a node representing an element which may be executed during a loop
 * iteration, excluding the initial loop condition, if any (but including the
 * tailing loop condition of do-while statements).
 */
ControlFlowNode getALoopIterationNode(LoopStmt loop) {
    result.getEnclosingStmt*().getEnclosingStmt*() = loop.getBody()
    or exists(Expr expr, Expr checkReachableExpr |
        expr = loop.(ForStmt).getAnUpdate()
        // Check if first update is reachable, other updates are only reachable through previous updates
        and checkReachableExpr = loop.(ForStmt).getUpdate(0)
        or
        expr = loop.(DoStmt).getCondition()
        and checkReachableExpr = expr
    |
        result = expr.getAChildExpr*().getControlFlowNode()
        // Make sure node is reachable from body (or from previous for loop update); ignore cases where
        // body always exits iteration and loop update or condition is never reached
        and exists(ControlFlowNode bodyNode |
            bodyNode.getEnclosingStmt*().getEnclosingStmt*() = loop.getBody()
            and bodyNode.getASuccessor() = checkReachableExpr.getAChildExpr*().getControlFlowNode()
        )
    )
}

/**
 * Gets a direct successor of `node` in the same iteration of `loop`.
 */
ControlFlowNode getASameIterationDirectSuccessorNode(LoopStmt loop, ControlFlowNode node) {
    exists(ControlFlowNode entryNode |
       entryNode = getLoopEntryNode(loop)
    |
        result.getEnclosingStmt().getEnclosingStmt*() = loop
        and result = node.getASuccessor()
        and result != entryNode
        // Ignore if node causes iteration of enclosing loop to continue, which might not
        // have condition and directly executes this loop again, e.g. `for(;;) while (...) { ... }`
        and result != loop
    )
}

/**
 * Gets a direct or transitive successor of `node` in the same iteration of `loop`.
 */
ControlFlowNode getASameIterationSuccessorNode(LoopStmt loop, ControlFlowNode node) {
    exists(ControlFlowNode successor |
        successor = getASameIterationDirectSuccessorNode(loop, node)
        and (
            result = successor
            or result = getASameIterationSuccessorNode(loop, successor)
        )
    )
}

/**
 * Gets a direct or transitive predecessor of `node` in the same iteration of `loop`,
 * excluding `for` statement initializers.
 */
ControlFlowNode getASameIterationPredecessorNode(LoopStmt loop, ControlFlowNode node) {
    exists(ControlFlowNode entryNode | entryNode = getLoopEntryNode(loop) |
        result = entryNode
        or exists(ControlFlowNode predecessor |
            node = getASameIterationDirectSuccessorNode(loop, predecessor)
            // Only consider nodes in loop
            and node = getASameIterationSuccessorNode(loop, entryNode)
        |
            result = node
            or result = getASameIterationPredecessorNode(loop, node)
        )
    )
}

/**
 * Gets a statement which exits the loop.
 */
Stmt getAnExitingStatement(LoopStmt loop) {
    result.(BreakStmt).(JumpStmt).getTarget() = loop
    or result.(ReturnStmt).getEnclosingStmt*() = loop.getBody()
    or exists(ThrowStmt throwStmt, RefType thrownExceptionType |
        result = throwStmt
        and throwStmt.getEnclosingStmt*() = loop.getBody()
        and thrownExceptionType = throwStmt.getThrownExceptionType()
        // Ignore if exception is caught within the loop body
        and not exists (TryStmt tryStmt |
            tryStmt.getEnclosingStmt*() = loop.getBody()
            and throwStmt.getEnclosingStmt+() = tryStmt.getBlock()
            and tryStmt.getACatchClause().getACaughtType() = thrownExceptionType.getSourceDeclaration*()
        )
    )
}
