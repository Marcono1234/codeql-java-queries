/**
 * Finds cases of lazy initialization where after checking that the
 * field is not intialized yet and the lock has been acquired, no
 * second check is performed:
 * ```
 * private volatile Writer writer;
 *
 * public Writer createWriter() {
 *     if (writer == null) {
 *         synchronized (this) {
 *             // A second check for `writer == null` is missing
 *             writer = ...;
 *         }
 *     }
 *     return writer;
 * }
 * ```
 *
 * If two threads concurrently try to retrieve the value, the second
 * thread will block and once the first thread has already initialized
 * the field value, the second thread will re-initialize it, discarding
 * the already initialized value potentially causing data loss or
 * corruption.
 * To fix this, after the lock has been acquired a second check should
 * be performed to detect if another thread has already initialized the
 * field.
 *
 * See https://en.wikipedia.org/wiki/Double-checked_locking#Usage_in_Java
 * 
 * @kind problem
 */

import java

import lib.ConcurrencyLib
import lib.Literals

predicate accessSameField(FieldAccess a, FieldAccess b) {
    a.getField() = b.getField()
    and (
        a.getField().isStatic()
        or a.isOwnFieldAccess() and b.isOwnFieldAccess()
        or exists (RefType enclosing |
            a.isEnclosingFieldAccess(enclosing)
            and b.isEnclosingFieldAccess(enclosing)
        )
        or accessSameField(a.getQualifier(), b.getQualifier())
    )
}

boolean defaultValueCheck(FieldAccess fieldAccess, EqualityTest conditionExpr) {
    // Ignore assert statements because they are not a proper check
    not conditionExpr.getEnclosingStmt() instanceof AssertStmt
    and accessSameField(conditionExpr.getAnOperand(), fieldAccess)
    and conditionExpr.getAnOperand() instanceof DefaultValueLiteral
    and result = conditionExpr.polarity()
}

from FieldAccess fieldAccess, ConditionNode firstCheck, SynchronizationStatement synchronizingStmt, Assignment assignment
where
    fieldAccess = assignment.getDest()
    // Ignore if assignment value is constant since then re-assignment is likely not problematic
    and not (
        assignment.getSource() instanceof CompileTimeConstantExpr
        or assignment.getSource() instanceof NullLiteral
    )
    // Ignore loops because there node is before and after other node (in next iteration)
    and not firstCheck.getEnclosingStmt().getEnclosingStmt*() instanceof LoopStmt
    and not assignment.getEnclosingStmt().getEnclosingStmt*() instanceof LoopStmt
    and firstCheck.getABranchSuccessor(defaultValueCheck(fieldAccess, firstCheck.getCondition())).getANormalSuccessor+() = synchronizingStmt
    and synchronizingStmt.includes(assignment)
    and not exists (ConditionNode secondCheck |
        synchronizingStmt.getControlFlowNode().getANormalSuccessor+() = secondCheck
        and secondCheck.getABranchSuccessor(defaultValueCheck(fieldAccess, secondCheck.getCondition())).getANormalSuccessor*() = assignment
    )
select assignment, "Assigns value without checking if field has been initialized in the meantime already"
