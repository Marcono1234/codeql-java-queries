/**
 * Finds equality or `instanceof` expressions which are redundant.
 * E.g.:
 * ```
 * if ("test".equals(var) && var instanceof String) {
 *     ...
 * }
 * ```
 */

import java

private predicate accessSameField(FieldAccess a, FieldAccess b) {
    a.isOwnFieldAccess() and b.isOwnFieldAccess()
    or exists (RefType enclosing |
        a.isEnclosingFieldAccess(enclosing)
        and b.isEnclosingFieldAccess(enclosing)
    )
    or accessSameVariable(a.getQualifier(), b.getQualifier())
}

predicate accessSameVariable(VarAccess a, VarAccess b) {
    exists (Variable var | var = a.getVariable() |
        var = b.getVariable()
        and (
            var instanceof LocalScopeVariable
            or var.(Field).isStatic()
            or accessSameField(a, b)
        )
    )
}

class ImplicitlyTypeCheckingExpr extends Expr {
    private Expr operand;
    private Type checkedType;
    
    ImplicitlyTypeCheckingExpr() {
        exists (Expr otherOperand |
            operand = this.(EQExpr).getAnOperand()
            and otherOperand = this.(EQExpr).getAnOperand()
            and otherOperand != operand
            and checkedType = otherOperand.getType()
        )
        or (
            operand = this.(InstanceOfExpr).getExpr()
            and checkedType = this.(InstanceOfExpr).getTypeName().getType()
        )
        // TODO: Causes some false positives for equals methods considering
        // other types equal, e.g. when comparing numeric values
        or this.(MethodAccess).getMethod() instanceof EqualsMethod
        and exists (MethodAccess equalsCall | equalsCall = this |
            (
                operand = equalsCall.getQualifier()
                and checkedType = equalsCall.getArgument(0).getType()
            )
            or (
                operand = equalsCall.getArgument(0)
                and checkedType = equalsCall.getReceiverType()
            )
        )
    }
    
    Expr getAnOperand() {
        result = operand
    }
    
    Type getCheckedType() {
        result = checkedType
    }
}

class OrExpr extends BinaryExpr {
    OrExpr() {
        this instanceof OrLogicalExpr
        or this instanceof OrBitwiseExpr 
    }
}

Expr getAnOrOperand(Expr expr) {
    result = expr
    or result = getAnOrOperand(expr.(OrExpr).getAnOperand())
}

predicate orChained(Expr a, Expr b) {
    exists (OrExpr orExpr |
        a = getAnOrOperand(orExpr.getLeftOperand())
        and b = getAnOrOperand(orExpr.getRightOperand())
    )
    or orChained(b, a)
}

class AndExpr extends BinaryExpr {
    AndExpr() {
        this instanceof AndLogicalExpr
        or this instanceof AndBitwiseExpr 
    }
}

Expr getAnAndOperand(Expr expr) {
    result = expr
    or result = getAnAndOperand(expr.(AndExpr).getAnOperand())
}

predicate andChained(Expr a, Expr b) {
    exists (AndExpr andExpr |
        a = getAnAndOperand(andExpr.getLeftOperand())
        and b = getAnAndOperand(andExpr.getRightOperand())
    )
    or andChained(b, a)
}

from ImplicitlyTypeCheckingExpr implicitCheck, InstanceOfExpr explicitCheck, Expr redundantExpr, Expr effectiveCheckExpr
where
    implicitCheck != explicitCheck
    and accessSameVariable(implicitCheck.getAnOperand(), explicitCheck.getExpr())
    and exists (Type explicitlyCheckedType | explicitlyCheckedType = explicitCheck.getTypeName().getType() |
        implicitCheck.getCheckedType() = explicitlyCheckedType
        or implicitCheck.getCheckedType().(RefType).getASourceSupertype*() = explicitlyCheckedType
    )
    and (
        (
            orChained(implicitCheck, explicitCheck)
            and redundantExpr = implicitCheck
            and effectiveCheckExpr = explicitCheck
        )
        or (
            andChained(implicitCheck, explicitCheck)
            and redundantExpr = explicitCheck
            and effectiveCheckExpr = implicitCheck
        )
    )
select redundantExpr, "Expression is redundant because it is already covered by $@.", effectiveCheckExpr, "this expression"
