/**
 * Finds `null` checks which are redundant because the checked variable is
 * very likely not `null`.
 * 
 * Note that this has overlap with CodeQL's query 'java/useless-null-check'.
 */

// Extends CodeQL's java/useless-null-check by covering more cases in which a
// null check is redundant

import java
import semmle.code.java.Conversions
import semmle.code.java.dataflow.Nullness
import semmle.code.java.dataflow.NullGuards
import semmle.code.java.controlflow.Guards

class NonNullExpr extends Expr {
    NonNullExpr() {
        // Compile time constant does not include null literal
        this instanceof CompileTimeConstantExpr
        // Conversion site from primitive to boxed
        or getType() instanceof PrimitiveType
        // Use CodeQL's predicate; note that this might not cover the cases checked above
        or this = clearlyNotNullExpr(_)
    }
}

from Variable var, RValue varRead, Expr nullCheck, string reason, Expr nonNullGuaranteeExpr, string nonNullGuaranteeExprDescription
where
    var.getAnAccess() = varRead
    // Use isnull=true to only consider guards checking for null, ignoring non-null
    // guards such as `instanceof`
    and nullCheck = basicOrCustomNullGuard(varRead, _, true)
    and (
        // Final variable for which all assigned values are non-null
        (
            var.isFinal()
            and nonNullGuaranteeExpr = var.getAnAssignedValue()
            and forall(Expr assignedValue | assignedValue = var.getAnAssignedValue() | assignedValue instanceof NonNullExpr)
            and reason = "being initialized with a non-null value $@"
            and nonNullGuaranteeExprDescription = "here"
        )
        // Or there is a previous variable access which guarantees that the variable
        // has a non-null value
        or (
            // Only consider local variables, for fields it would require checking the call
            // graph and might also yield false positives when fields are set using reflection
            var instanceof LocalScopeVariable
            and exists(VarAccess nullGuard |
                nullGuard.getVariable() = var
                // Ignore if there is a reassignment between null guard and varRead
                and not exists(AssignExpr reassign |
                    reassign.getDest() = var.getAnAccess()
                    and nullGuard.getControlFlowNode().getASuccessor+() = reassign
                    and reassign.getControlFlowNode().getASuccessor+() = varRead
                )
            |
                strictlyDominates(nullGuard.getControlFlowNode(), varRead.getControlFlowNode())
                and (
                    (
                        nonNullGuaranteeExpr = nullGuard.(LValue).getRHS()
                        and nonNullGuaranteeExpr instanceof NonNullExpr
                        and reason = "being assigned a non-null value $@"
                        and nonNullGuaranteeExprDescription = "here"
                    )
                    // Previous dereference guarantees that value is non-null
                    /*
                     * Note that this is the reverse of CodeQL's java/dereferenced-value-may-be-null
                     * That query assumes that a dereference followed by null check indicates the
                     * value might be null; this query here assumes the value is not null and the null
                     * check is useless
                     */
                    or (
                        nonNullGuaranteeExpr = nullGuard.(RValue)
                        and dereference(nonNullGuaranteeExpr)
                        // Ignore if dereference occurs in try statement, then it would not be a
                        // guard for an access in the finally block (since that would be executed
                        // even when the variable is null and caused a NullPointerException)
                        and not exists(TryStmt tryStmt |
                            nullGuard.getAnEnclosingStmt() = tryStmt.getBlock()
                            and varRead.getAnEnclosingStmt() = tryStmt.getFinally()
                        )
                        and reason = "being dereferenced $@"
                        and nonNullGuaranteeExprDescription = "here"
                    )
                )
                // Or a previous null guard which controls the redundant null guard
                // TODO: Not tested yet
                or exists(Guard guard, boolean branch, boolean isNull, boolean nonNullBranch |
                    // Determine which value `branch` must have to be the non-null branch
                    guard = basicOrCustomNullGuard(nullGuard.(LValue), branch, isNull)
                    and if isNull = true then nonNullBranch = branch.booleanNot()
                    else nonNullBranch = branch
                    and guard.controls(varRead.getBasicBlock(), nonNullBranch)
                    and reason = "$@ null check"
                    and nonNullGuaranteeExpr = guard
                    and nonNullGuaranteeExprDescription = "this"
                )
            )
        )
    )
select varRead, "Variable cannot be null due to " + reason, nonNullGuaranteeExpr, nonNullGuaranteeExprDescription
