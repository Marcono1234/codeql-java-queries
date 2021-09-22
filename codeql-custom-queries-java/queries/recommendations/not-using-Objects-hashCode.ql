/**
 * Finds `hashCode()` calls which are guarded by a `null` check and use
 * `0` as hash code in case the object is `null`. Such code can be replaced
 * with `java.util.Objects.hashCode(Object)` which behaves the same way but
 * increases readability.
 */

import java
import lib.VarAccess

Stmt getStmtOrSingletonChild(Stmt stmt) {
    result = stmt
    or result = stmt.(SingletonBlock).getStmt()
}

from EqualityTest nullCheck, boolean checksNull, MethodAccess hashCodeCall, IntegerLiteral nullHashCode
where
    nullCheck.getAnOperand() instanceof NullLiteral
    and checksNull = nullCheck.polarity()
    and hashCodeCall.getMethod() instanceof HashCodeMethod
    // Only consider value 0 so its behavior is the same as Objects.hashCode
    and nullHashCode.getIntValue() = 0
    and accessSameVarOfSameOwner(nullCheck.getAnOperand(), hashCodeCall.getQualifier())
    and (
        exists(ConditionalExpr conditionalExpr |
            conditionalExpr.getCondition() = nullCheck
            and nullHashCode = conditionalExpr.getBranchExpr(checksNull)
            and hashCodeCall = conditionalExpr.getBranchExpr(checksNull.booleanNot())
        )
        or exists(IfStmt ifStmt, Expr thenExpr, Expr elseExpr |
            if checksNull = true then (
                thenExpr = nullHashCode
                and elseExpr = hashCodeCall
            ) else (
                thenExpr = hashCodeCall
                and elseExpr = nullHashCode
            )
        |
            ifStmt.getCondition() = nullCheck
            and getStmtOrSingletonChild(ifStmt.getThen()).(ReturnStmt).getResult() = thenExpr
            and getStmtOrSingletonChild(ifStmt.getElse()).(ReturnStmt).getResult() = elseExpr
        )
    )
select hashCodeCall, "hashCode() call guarded by $@ null check should be replaced with Objects.hashCode(Object)", nullCheck, "this"
