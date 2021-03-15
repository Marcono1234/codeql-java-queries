/**
 * Finds usage of the short circuiting boolean operators `||` and `&&` whose
 * left operand appears to be more expensive than its right operand, e.g.:
 * ```
 * if (expensiveCheck() || fieldA == fieldB) {
 *     ...
 * }
 * ```
 *
 * The advantage of the short circuiting operators is that their right operand
 * is not evaluated if its value would not have an effect on the result.
 * Therefore the left operand should (if possible) be cheaper than the right one.
 *
 * However, this query might find false positives where the left operand has
 * side effects and therefore cannot be switched with the right operand without
 * changing the behavior. Hence the findings reported by this query should be
 * carefully examined.
 */

import java

class ShortCircuitingExpr extends BinaryExpr {
    ShortCircuitingExpr() {
        this instanceof AndLogicalExpr
        or this instanceof OrLogicalExpr
    }
}

/**
 * Method which is known to be modifying, e.g. due to the requirements imposed
 * by its documentation.
 */
class ModifyingMethod extends Method {
    ModifyingMethod() {
        getDeclaringType().hasQualifiedName("java.util", "Collection")
        and getNumberOfParameters() = 1
        and getReturnType() instanceof BooleanType
        and hasName([
            "add", "addAll",
            "remove", "removeAll", "removeIf",
            "retainAll"
        ])
    }
}

class ModifyingCall extends Call {
    ModifyingCall() {
        // Certain methods are known to be modifying
        this.(MethodAccess).getMethod().getSourceDeclaration().getAnOverride*() instanceof ModifyingMethod
        // Only consider modifying if method cannot be overridden, otherwise would cause
        // too many false positives
        or exists (Callable c, Block body | c = getCallee() and body = c.getBody() |
            (
                not c.(Method).isOverridable()
                or this.(MethodAccess).getReceiverType().isFinal()
            )
            and exists (Stmt stmt, Expr expr | stmt.getParent+() = c and expr.getParent+() = stmt |
                // Ignore if only local variable is modified
                expr instanceof NonLocalVarModifyingExpr
            )
        )
    }
}

class ModifyingExpr extends Expr {
    ModifyingExpr() {
        // Check for assignment instead of LValue here because assignment
        // to array elements should be considered as well
        this instanceof Assignment
        or this instanceof UnaryAssignExpr
        or this instanceof ModifyingCall
    }
}

/**
 * A modifying expression which ignores modifications to local variables.
 */
class NonLocalVarModifyingExpr extends ModifyingExpr {
    NonLocalVarModifyingExpr() {
        not this.(LValue).getVariable() instanceof LocalScopeVariable
    }
}

class NonModifyingExpr extends Expr {
    NonModifyingExpr() {
        not this instanceof ModifyingExpr
    }
}

class CheapMethodCall extends MethodAccess {
    CheapMethodCall() {
        exists (Method m, Block body | m = getMethod() and body = m.getBody() |
            // Only if method cannot be overridden can be sure that method is cheap
            (
                not m.isOverridable()
                or getReceiverType().isFinal()
            )
            and body.getNumStmt() = 1
            // Don't match CheapMethodCall here because transitive cheap method call chain
            // is not cheap
            and body.getAStmt().(ReturnStmt).getResult() instanceof CompleteCheapExpr
        )
    }
}

class CheapExpr extends Expr {
    CheapExpr() {
        not (
            this instanceof Call
            or this instanceof ArrayCreationExpr
            or this instanceof SwitchExpr
            or this instanceof ModifyingExpr
        )
    }
}

/**
 * A cheap expression whose children are cheap as well.
 */
class CompleteCheapExpr extends CheapExpr {
    CompleteCheapExpr() {
        forall (Expr child | child = getAChildExpr() |
            child instanceof CompleteCheapExpr
        )
    }
}

/**
 * A cheap expression (including a cheap method call).
 */
class CheapExprOrMethodCall extends Expr {
    CheapExprOrMethodCall() {
        this instanceof CheapExpr
        or this instanceof CheapMethodCall
    }
}

predicate notInAssert(Expr expr) {
    not expr.getEnclosingStmt().getEnclosingStmt*() instanceof AssertStmt
}

class ExpensiveCallable extends Callable {
    ExpensiveCallable() {
        // Assume that callable with more than 3 parameters is expensive
        getNumberOfParameters() > 3
        // If there exists a direct override which is expensive, assume
        // that method is in general expensive
        or if isAbstract() then exists (ExpensiveCallable overriding |
            overriding.(Method).overrides(this)
        )
        else (
            exists(Call expensiveCall |
                expensiveCall.getEnclosingCallable() = this
                and notInAssert(expensiveCall)
                and expensiveCall.getCallee() instanceof ExpensiveCallable
            )
            // Rough estimation for what could be considered an expensive method
            or count (Stmt stmt |
                not (stmt instanceof AssertStmt or stmt instanceof Block)
                and stmt.getEnclosingCallable() = this
            ) > 5
        )
    }
}

class ExpensiveExpr extends Expr {
    ExpensiveExpr() {
        if this instanceof Call then (
            this.(Call).getCallee() instanceof ExpensiveCallable
        ) else (
            not this instanceof CheapExpr
            // CheapExpr excludes assignments, so have to exclude them here as well
            // because they are not expensive
            and not this instanceof Assignment
            and not this instanceof UnaryAssignExpr
        )
    }
}

from ShortCircuitingExpr shortCircuitingExpr, ExpensiveExpr expensiveExpr
where
    expensiveExpr.getParent*() = shortCircuitingExpr.getLeftOperand()
    // Make sure that parent expression has not been reported yet
    and not exists (ExpensiveExpr parent |
        parent = expensiveExpr.getParent+()
        and parent = shortCircuitingExpr.getLeftOperand().getAChildExpr*()
    )
    // Cannot switch operands if left operand is modifying
    and not exists (Expr leftOperandChild | leftOperandChild = shortCircuitingExpr.getLeftOperand().getAChildExpr*() |
        leftOperandChild instanceof ModifyingExpr
    )
    and forall (Expr rightOperandChild | rightOperandChild = shortCircuitingExpr.getRightOperand().getAChildExpr*() |
        rightOperandChild instanceof CheapExprOrMethodCall
    )
select shortCircuitingExpr, "Evaluation of $@ of left operand is more expensive than evaluation of right operand; should switch operands.", expensiveExpr, "this expression"
