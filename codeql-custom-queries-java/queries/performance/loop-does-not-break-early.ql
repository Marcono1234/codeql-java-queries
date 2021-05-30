/**
 * Finds loops which appear to check for a specific condition but instead of
 * breaking the loop once the condition is found to be the case, continue until
 * the end of the loop is reached. E.g.:
 * ```java
 * boolean containsChild = false;
 * for (person : persons) {
 *     if (person.isChild()) {
 *         containsChild = true;
 *         // Should `break;` here
 *     }
 * }
 * ```
 * 
 * Note that this query is not very accurate because it cannot determine
 * whether method calls in the loop have any side effects.
 */

import java
import semmle.code.java.controlflow.Guards
import lib.Loops

private predicate isDeclaredOutsideOf(Variable var, Stmt s) {
    var instanceof Field
    or (
        var instanceof LocalVariableDecl
        and not var.(LocalVariableDecl).getDeclExpr().getAnEnclosingStmt() = s
    )
}

/*
 * Check for a `boolean` flag variable which is assigned inside the loop
 */
from LoopStmt loop, Variable flagVar, LValue assignLValue, AssignExpr assign
where
    assign.getAnEnclosingStmt() = loop.getBody()
    and assign.getDest() = assignLValue
    and assignLValue = flagVar.getAnAccess()
    // Flag variable must be declared outside of loop
    and isDeclaredOutsideOf(flagVar, loop)
    // Only consider if flag variable is assigned a boolean literal
    and assign.getRhs() instanceof BooleanLiteral
    // Ignore if flag variable is accessed anywhere else in the loop
    // or in the condition of the loop
    and not exists(VarAccess otherAccess |
        otherAccess.getVariable() = flagVar
        and (
            otherAccess.getAnEnclosingStmt() = loop.getBody()
            or otherAccess.getParent*() = loop.getCondition()
        )
        and otherAccess != assignLValue
    )
    // And flag is set conditionally; ignore loops which set flag unconditionally
    // to indicate that loop iterated at least once
    and exists(Guard guard |
        guard.getEnclosingStmt().getEnclosingStmt*() = loop.getBody()
    |
        guard.controls(assign.getBasicBlock(), _)
    )
    // Ignore if there is another expression after flag assignment, then loop
    // can most likely not break early
    and not exists(Expr subsequentExpr |
        // TODO: Not sure if this is correct; control flow graph models previous nodes
        // as successors for next iteration, so maybe this causes false negatives
        assign.getControlFlowNode().getASuccessor+() = subsequentExpr.getControlFlowNode()
        and subsequentExpr.getControlFlowNode().getASuccessor*() = loop.getBody().(BasicBlock).getLastNode()
    )
    // To reduce false positives ignore if there is any other write in the loop
    // (then loop can most likely not break early)
    and not exists(LValue otherWrite |
        otherWrite.getAnEnclosingStmt() = loop.getBody()
        and otherWrite != assignLValue
    )
    // And there is no exiting statement after assign
    and not assign.getControlFlowNode().getASuccessor*() = getAnExitingStatement(loop).getControlFlowNode()
select loop, "Loop does not break after setting boolean flag with $@ assignment", assign, "this"
