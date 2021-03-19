/**
 * Finds declarations of local variables for which the first assignment of the variable
 * occurs in the same block but at a different location. To improve readability the
 * declaration of the variable should be moved to the first assignment.
 * E.g.:
 * ```java
 * String result;
 * ...
 * result = getResult();
 * ```
 * Should be instead written as:
 * ```java
 * ...
 * String result = getResult();
 * ```
 *
 * Note that in some cases, e.g. in unit tests or when there is a chain of compound
 * assignments, having variable declaration and initialization separately might improve
 * readability. This query tries to avoid reporting these cases.
 */

import java

private AssignExpr getAVarAssign(Variable var) {
    result.getDest() = var.getAnAccess()
}

/**
 * Gets the immediately subsequent statement to `s`, but only if it performs an
 * assignment of `var`.
 */
private Stmt getNextAssignStmt(Variable var, Stmt s) {
    result.(ExprStmt).getExpr().(Assignment).getDest() = var.getAnAccess()
    and result.getParent() = s.getParent()
    and result.getIndex() = s.getIndex() + 1
}

private predicate hasAssignmentChain(LocalVariableDeclStmt localVarDecl, Variable var) {
    // Check if there are at least two assignment statements following the variable declaration
    exists(Stmt nextAssign |
        nextAssign = getNextAssignStmt(var, localVarDecl)
        and exists(getNextAssignStmt(var, nextAssign))
    )
}

from LocalVariableDeclStmt localVarDecl, Variable var, AssignExpr firstAssign
where
    var = localVarDecl.getAVariable().getVariable()
    and firstAssign = getAVarAssign(var)
    // Make sure assignment occurs in same control flow block; ignore if it only occurs conditionally
    and firstAssign.getBasicBlock() = localVarDecl.getBasicBlock()
    // And assignment also appears in same block; ignore for example when variable is assigned in
    // `try` body
    and firstAssign.getEnclosingStmt().(ExprStmt).getEnclosingStmt().(BlockStmt) = localVarDecl.getEnclosingStmt()
    // And no intializer exists
    and not exists(var.getInitializer())
    // Make sure that there is no other assignment in front
    and not exists(AssignExpr otherAssign |
        otherAssign = getAVarAssign(var)
        and otherAssign != firstAssign
    |
        otherAssign.getControlFlowNode().getASuccessor+() = firstAssign.getControlFlowNode()
    )
    // Ignore assignment chains (e.g. multiple `var |= ...`), for them declaring variable
    // separately might improve readability
    and not hasAssignmentChain(localVarDecl, var)
    // Ignore test classes because they often declare a variable separately once and then
    // reuse it for multiple tests
    and not localVarDecl.getEnclosingCallable().getDeclaringType() instanceof TestClass
select localVarDecl, "Variable declaration should be moved to first assignment of variable $@", firstAssign, "here"
