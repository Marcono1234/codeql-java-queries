/**
 * Finds switch statements or expressions on `this`, where the type of `this`
 * is an enum.
 * It might be better to instead use an instance field or make the method
 * containing the switch abstract to have the enum constants implement the
 * behavior. This prevents accidentially missing an enum constant.
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
    
    predicate isCompleteEnumSwitch() {
        forall (EnumConstant enumConstant |
            enumConstant = getSelectorExpr().getType().(EnumType).getAnEnumConstant()
            |
            getAConstCase().getValue(_).(FieldRead).getField() = enumConstant
        )
    }
}

from SwitchStmtOrExpr switch, ThisAccess thisAccess
where
    thisAccess = switch.getSelectorExpr()
    and thisAccess.getType() instanceof EnumType
    // If switch is incomplete, adding field which is only set by some constants,
    // or method which only some constants override is also error-prone, so switch
    // on `this` might be acceptable
    and switch.isCompleteEnumSwitch()
select switch
