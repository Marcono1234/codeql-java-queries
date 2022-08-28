/**
 * Finds `if` statements where the 'then' branch always stops execution of the block enclosing
 * the `if` statement, for example because it executes a `return` statement, and where the 'else'
 * branch contains deeply nested statements. In such cases the `else` could be omitted to lift
 * up its code directly into the parent statement. This would therefore decrease the nesting
 * of the code and might make it more readable.
 * 
 * For example:
 * ```java
 * if (i < 5) {
 *     return true;
 * } else {
 *     ... deeply nested code
 * }
 * ```
 * Could be rewritten to:
 * ```java
 * if (i < 5) {
 *     return true;
 * }
 * 
 * ... deeply nested code
 * ```
 * 
 * @kind problem
 */

import java

Stmt getALastExecutedStmt(BlockStmt block) {
    result = block.(SingletonBlock).getStmt()
    or
    result.getEnclosingStmt+() = block
    and not exists(Stmt successor |
        successor.getEnclosingStmt+() = block
        // TODO: This will cause false positives for loops
        and block.getControlFlowNode().getASuccessor() = successor
    )
}

predicate isJumpingStmt(Stmt s) {
    s instanceof ReturnStmt
    or s instanceof ThrowStmt
    or s instanceof JumpStmt
}

int getATypeNestingDepth(RefType t) {
    // + 1 for the class itself
    if exists(t.getACallable()) then (
        result = 1 + getANestingDepth(t.getACallable().getBody())
    )
    else result = 1
}

int getANestingDepth(Stmt s) {
    if (s instanceof BlockStmt) then (
        result = 1 + getANestingDepth(s.(BlockStmt).getAChild())
    )
    else if (s instanceof SwitchStmt) then (
        result = 1 + getANestingDepth(s.(SwitchStmt).getAStmt())
    )
    else if (s instanceof LocalTypeDeclStmt) then (
        result = getATypeNestingDepth(s.(LocalTypeDeclStmt).getLocalType())
    )
    // Special case for functional expressions because they would otherwise be treated like anonymous classes
    else if exists(FunctionalExpr e | e.getEnclosingStmt() = s) then (
        exists(FunctionalExpr e | e.getEnclosingStmt() = s |
            e instanceof MemberRefExpr and result = 0
            or
            e.(LambdaExpr).hasExprBody() and result = 0
            or
            result = getANestingDepth(e.(LambdaExpr).getStmtBody())
        )
    )
    else if exists(AnonymousClass c | c.getClassInstanceExpr().getEnclosingStmt() = s) then (
        exists(AnonymousClass c | c.getClassInstanceExpr().getEnclosingStmt() = s |
            result = getATypeNestingDepth(c)
        )
    )
    else result = 0 or result = getANestingDepth(s.getAChild())
}

int getStmtNestingDepth(Stmt s) {
    result = max(getANestingDepth(s))
}

from IfStmt ifStmt, Stmt thenStmt, Stmt elseStmt
where
    thenStmt = ifStmt.getThen()
    and elseStmt = ifStmt.getElse()
    and (
        isJumpingStmt(thenStmt)
        or forex(Stmt lastStmt | lastStmt = getALastExecutedStmt(thenStmt) |
            isJumpingStmt(lastStmt)
        )
    )
    and getStmtNestingDepth(elseStmt) >= 4
    // Ignore `if ... else if ...`
    and not elseStmt instanceof IfStmt
    // Ignore in case this is part of `if ... else if ...`; in that case omitting `else` could result in
    // previous 'then' block executing `else` code
    and not any(IfStmt s).getElse() = ifStmt
select elseStmt, "Should omit `else` to decrease the level of nested code"
