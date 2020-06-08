/**
 * Finds methods which override one of the `java.lang.Object` methods
 * `toString()`, `equals(Object)` or `hashCode()`, but throw an exception.
 * It should be verified that throwing an exception is indeed necessary
 * and falling back to the implementation provided by `java.lang.Object`
 * is not acceptable.
 * If the exception is thrown to indicate that the method should be overridden
 * by subclasses, then it would be safer to add a separate abstract protected
 * method to which that method delegates.
 */

import java

class NotThrowingMethod extends Method {
    NotThrowingMethod() {
        hasStringSignature("toString()")
        or this instanceof EqualsMethod
        or this instanceof HashCodeMethod
    }
}

class SwitchStmtOrExpr extends Top {
    SwitchStmtOrExpr() {
        this instanceof SwitchStmt
        or this instanceof SwitchExpr
    }
    
    Expr getSelectorExpr() {
        result = this.(SwitchStmt).getExpr()
        or result = this.(SwitchExpr).getExpr()
    }
    
    ConstCase getAConstCase() {
        result.getSwitch() = this
        or result.getSwitchExpr() = this
    }
    
    DefaultCase getDefaultCase() {
        result.getSwitch() = this
        or result.getSwitchExpr() = this
    }
}

predicate isCompleteEnumSwitch(SwitchStmtOrExpr switch) {
    forall (EnumConstant enumValue |
        enumValue = switch.getSelectorExpr().getType().(EnumType).getAnEnumConstant()
        |
        switch.getAConstCase().getValue(_).(FieldRead).getField() = enumValue
    )
}

from ThrowStmt throwStmt
where
    throwStmt.getEnclosingCallable().(Method).getAnOverride*() instanceof NotThrowingMethod
    // Throw stmt does is not part of exception handling
    and not exists (CatchClause catchClause |
        throwStmt.getEnclosingStmt() = catchClause.getBlock()
    )
    // Ignore throw stmts in default case of switch over enum covering
    // all enum constants; default case might be needed to make code compilable
    and not exists (SwitchStmtOrExpr switch, DefaultCase defaultCase |
        defaultCase = switch.getDefaultCase()
        and throwStmt.getParent() = switch
        and isCompleteEnumSwitch(switch)
        and (
            // Switch expression with rule (`default ->`) syntax
            throwStmt.getEnclosingStmt*() = defaultCase.getRuleStatement()
            // For SwitchBlockStatementGroup (`default:`) statements are not children
            // of DefaultCase, so have to make sure that throw appears after `default`
            // and before any other `case` (if any)
            or throwStmt.getBasicBlock() = defaultCase
        )
    )
select throwStmt
