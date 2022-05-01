/**
 * Finds `null` checks which are redundant because the checked variable is
 * very likely not `null`.
 * 
 * Note that this has overlap with CodeQL's query 'java/useless-null-check'.
 */

// Extends CodeQL's java/useless-null-check by covering more cases in which a
// null check is redundant

// TODO: With https://github.com/github/codeql/pull/5762 being merged this query might
// become redundant

import java
import semmle.code.java.Conversions
import semmle.code.java.dataflow.Nullness
import semmle.code.java.dataflow.NullGuards
import semmle.code.java.controlflow.Guards

class NonNullExpr extends Expr {
    Expr reason;

    NonNullExpr() {
        reason = this
        and (
            // Compile time constant does not include null literal
            this instanceof CompileTimeConstantExpr
            // Conversion site from primitive to boxed
            or getType() instanceof PrimitiveType
        )
        // Use CodeQL's predicate; note that this might not cover the cases checked above
        or this = clearlyNotNullExpr(reason)
    }

    Expr getReason() { result = reason }
}

private string getReasonSuffix(NonNullExpr nonNullExpr, Expr reason) {
    reason = nonNullExpr.getReason()
    // If reason and expression are the same omit the reason from the message
    // See also https://codeql.github.com/docs/writing-codeql-queries/defining-the-results-of-a-query/#adding-a-link-to-the-similar-file
    // > If there are more pairs of additional columns than there are placeholder markers, then the trailing columns are ignored.
    and if reason = nonNullExpr then result = ""
    else result = " ($@)"
}

from Variable var, RValue varRead, Expr nullCheck, string reason, Expr nonNullGuaranteeExpr, string nonNullGuaranteeExprDescription, Expr nonNullGuaranteeReasonExpr
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
            and reason = "being initialized with a non-null value $@" + getReasonSuffix(nonNullGuaranteeExpr, nonNullGuaranteeReasonExpr)
            and nonNullGuaranteeExprDescription = "here"
        )
        // Or there is a previous variable access which guarantees that the variable
        // has a non-null value
        or (
            // Only consider local variables, for fields it would require checking the call
            // graph and might also yield false positives when fields are set using reflection
            var instanceof LocalScopeVariable
            // TODO: Some of the dataflow checks here are redundant because clearlyNotNullExpr() already
            // checks for this
            and exists(VarAccess nullGuard, ControlFlowNode nullGuardNode |
                nullGuard.getVariable() = var
                // Ignore if there is a reassignment between null guard and varRead
                and not exists(AssignExpr reassign |
                    reassign.getDest() = var.getAnAccess()
                    and nullGuardNode.getASuccessor+() = reassign
                    and reassign.getControlFlowNode().getASuccessor+() = varRead
                )
            |
                // Non-null assignment before null check
                // Note: Check nullGuard.getParent() because for LValue control flow node would be
                // the var access, which is not relevant, see also https://github.com/github/codeql/issues/5652
                nullGuardNode = nullGuard.getParent().(Expr).getControlFlowNode()
                and strictlyDominates(nullGuardNode, varRead.getControlFlowNode())
                and (
                    nonNullGuaranteeExpr = nullGuard.(LValue).getRhs().(NonNullExpr)
                    and reason = "being assigned a non-null value $@" + getReasonSuffix(nonNullGuaranteeExpr, nonNullGuaranteeReasonExpr)
                    and nonNullGuaranteeExprDescription = "here"
                )
                or
                // Or AssignAdd performing String concatenation; result stored in variable will never be null
                // (neither will a NullPointerException be thrown), even when one or both values are null
                // Note: Check nullGuard.getParent() because for LValue control flow node would be
                // the var access, which is not relevant, see also https://github.com/github/codeql/issues/5652
                nullGuardNode = nullGuard.getParent().(Expr).getControlFlowNode()
                and strictlyDominates(nullGuardNode, varRead.getControlFlowNode())
                and (
                    nonNullGuaranteeExpr.(AssignAddExpr).getDest() = nullGuard
                    and nonNullGuaranteeExpr.getType() instanceof TypeString
                    and reason = "being assigned the result of $@ String concatenation"
                    and nonNullGuaranteeExprDescription = "this"
                    and nonNullGuaranteeReasonExpr = nonNullGuaranteeExpr
                )
                or
                // Previous dereference guarantees that value is non-null
                /*
                * Note that this is the reverse of CodeQL's java/dereferenced-value-may-be-null
                * That query assumes that a dereference followed by null check indicates the
                * value might be null; this query here assumes the value is not null and the null
                * check is useless
                */
                nullGuardNode = nullGuard.getControlFlowNode()
                and strictlyDominates(nullGuardNode, varRead.getControlFlowNode())
                and (
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
                    and nonNullGuaranteeReasonExpr = nonNullGuaranteeExpr
                )
                or
                // Or a previous null guard which controls the redundant null guard
                nullGuardNode = nullGuard.getControlFlowNode()
                and exists(Guard guard, boolean branch, boolean isNull, boolean nonNullBranch |
                    // Determine which value `branch` must have to be the non-null branch
                    guard = basicOrCustomNullGuard(nullGuard, branch, isNull)
                    and if isNull = true then nonNullBranch = branch.booleanNot()
                    else nonNullBranch = branch
                    and guard.controls(varRead.getBasicBlock(), nonNullBranch)
                    and reason = "$@ null check"
                    and nonNullGuaranteeExpr = guard
                    and nonNullGuaranteeExprDescription = "this"
                    and nonNullGuaranteeReasonExpr = nonNullGuaranteeExpr
                )
            )
        )
    )
select varRead, "Variable cannot be null due to " + reason, nonNullGuaranteeExpr, nonNullGuaranteeExprDescription, nonNullGuaranteeReasonExpr, "reason"
