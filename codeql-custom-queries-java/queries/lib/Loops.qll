import java

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
