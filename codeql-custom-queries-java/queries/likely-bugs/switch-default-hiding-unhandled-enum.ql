/**
 * Finds `switch` statements or expressions on enum types which have a
 * `default` case which appears to be assuming that all enum constants
 * are covered and only exists to make the code compilable, but the
 * switch is not actually covering all enum constants.
 *
 * See also CodeQL's `java/missing-case-in-switch` which checks for
 * switch without a default case.
 */

import java

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

EnumConstant getMissingEnumConstant(SwitchStmtOrExpr switch) {
    result.getType() = switch.getSelectorExpr().getType()
    and not exists (ConstCase constCase |
        constCase = switch.getAConstCase()
        and constCase.getValue(_).(FieldRead).getField() = result
    )
}

predicate handlesUnknownEnumConstant(ThrowStmt throwStmt) {
    exists (ClassInstanceExpr newExpr |
        newExpr = throwStmt.getExpr()
        and (
            // Throwing subclass of Error (e.g. AssertionError)
            newExpr.getConstructedType().getAnAncestor() instanceof TypeError
            // Throwing RuntimeException without arguments
            or (
                newExpr.getConstructedType().hasQualifiedName("java.lang", "RuntimeException")
                and newExpr.getNumArgument() = 0
            )
            // Creating message which suggests that enum constant is unknown
            or exists (StringLiteral stringLiteral |
                stringLiteral.getParent*() = newExpr
                // "unknown" or "unrecognized"
                and stringLiteral.getValue().regexpMatch("(?s).*[uU](?:nknown|nrecognized).*")
            )
        )
    )
}

from SwitchStmtOrExpr switch, ThrowStmt throwStmt, EnumType enumType
where
    enumType = switch.getSelectorExpr().getType()
    and throwStmt.getBasicBlock() = switch.getDefaultCase()
    and handlesUnknownEnumConstant(throwStmt)
select switch, enumType, strictconcat(getMissingEnumConstant(switch).getName(), ", ")
