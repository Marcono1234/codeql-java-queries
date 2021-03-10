/**
 * Finds calls to `toString()` on `CharSequence` or subtypes, where the
 * methods called on the result could have instead been called on the
 * receiver of `toString()`. This would avoid the creation of the
 * intermediate String by `toString()`.
 * E.g.:
 * ```
 * StringBuilder sb = ...;
 * // `toString()` call can be avoided; method `isEmpty()` is also
 * // present on StringBuilder
 * String s = sb.toString();
 * if (s.isEmpty()) {
 *     ...
 * }
 * ```
 */
 
// TODO: Improve performance of this query

import java
import semmle.code.java.dataflow.DataFlow

class LeakingExpr extends Expr {
    LeakingExpr() {
        // Leaks by passing it as argument to call
        any(Call c).getAnArgument() = this
        // Leaks by assigning to field
        or any(FieldWrite w).getRHS() = this
        // Leaks by storing in array
        or exists(AssignExpr assign |
            assign.getRhs() = this
            and assign.getDest() instanceof ArrayAccess
        )
        // Leaks by putting in new array
        or any(ArrayInit a).getAnInit() = this
        // Leaks by returning
        or any(ReturnStmt r).getResult() = this
        // Leaks by being captured, e.g. in lambda, inner class, ...
        or exists(LocalScopeVariable var |
            this = var.getAnAssignedValue()
            and var.getAnAccess().getEnclosingCallable() != getEnclosingCallable()
        )
    }
}

predicate isLeaked(Expr leaked) {
    DataFlow::localFlow(DataFlow::exprNode(leaked), DataFlow::exprNode(any(LeakingExpr e)))
}

class TypeWithStringAlternatives extends RefType {
    TypeWithStringAlternatives() {
        hasQualifiedName("java.lang", [
            "CharSequence",
            "StringBuilder",
            "StringBuffer"
        ])
    }
}

class ObjectMethod extends Method {
    ObjectMethod() {
        getDeclaringType() instanceof TypeObject
    }
}

/**
 * Holds if `call` performed (indirectly) on `t.toString()` (where `t`'s type is
 * `toStringReceiverType`), has an alternative which would not require calling
 * `toString()`, but instead directly calling a method on `t`.
 */
predicate hasNonStringAlternative(MethodAccess call, RefType toStringReceiverType) {
    exists(Method m, Method alternative | m = call.getMethod() |
        toStringReceiverType.getASourceSupertype*() = alternative.getDeclaringType()
        // Don't consider methods of custom subclasses because they might behave differently
        and alternative.getDeclaringType() instanceof TypeWithStringAlternatives
        and m.getStringSignature() = alternative.getStringSignature()
        and (
            // Same return types
            m.getReturnType() = alternative.getReturnType()
            // Or could switch to alternative because its return type would work as well
            or (
                m.getReturnType() instanceof TypeString
                // Result is not leaked
                and not isLeaked(call)
                and forall(MethodAccess callOnReturned |
                    DataFlow::localFlow(DataFlow::exprNode(call), DataFlow::exprNode(callOnReturned.getQualifier()))
                |
                    hasNonStringAlternative(callOnReturned, alternative.getReturnType())
                )
            )
        )
        // Ignore methods inherited from Object; they are likely not an alternative
        and not alternative.getSourceDeclaration().overridesOrInstantiates(any(ObjectMethod o))
    )
}

class Switch extends Top {
    Expr getExpr() {
        result = this.(SwitchStmt).getExpr()
        or result = this.(SwitchExpr).getExpr()
    }
}

from MethodAccess toStringCall, RefType receiverType
where
    toStringCall.getMethod().hasStringSignature("toString()")
    and receiverType = toStringCall.getReceiverType()
    and receiverType.getASourceSupertype*() instanceof TypeWithStringAlternatives
    // Result is not leaked
    and not isLeaked(toStringCall)
    // And not part of String concatenation (because that only works for String)
    and not exists(Expr concatPiece |
        DataFlow::localFlow(DataFlow::exprNode(toStringCall), DataFlow::exprNode(concatPiece))
    |
        any(AddExpr concatExpr).getAnOperand() = concatPiece
        or any(AssignAddExpr concatExpr).getRhs() = concatPiece
        // As destination and source of a compound concatentation expression `var += ...`
        or exists(Variable var |
            concatPiece = var.getAnAssignedValue()
            and any(AssignAddExpr concatExpr).getDest() = var.getAnAccess()
        )
    )
    // And result is not used in `switch` (because that only supports String)
    and not DataFlow::localFlow(DataFlow::exprNode(toStringCall), DataFlow::exprNode(any(Switch s).getExpr()))
    // TODO: Will yield some false positives for StringBuilder and StringBuffer in case they
    //       are modified after `toString()` but before other calls on result of `toString()`
    // TODO: Have to verify that `toString()` result is used at all, though this will likely decrease
    //       performance of this query even further
    and forall(MethodAccess call |
        DataFlow::localFlow(DataFlow::exprNode(toStringCall), DataFlow::exprNode(call.getQualifier()))
    |
        hasNonStringAlternative(call, toStringCall.getReceiverType())
    )
    // And there is no access on fields (might be the case for custom subtypes)
    and not DataFlow::localFlow(DataFlow::exprNode(toStringCall), DataFlow::exprNode(any(FieldAccess f).getQualifier()))
select toStringCall, "toString() call can be avoided; all methods on result can directly be called"
