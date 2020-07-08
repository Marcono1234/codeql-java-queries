/**
 * Finds checks on strings or lists which try to find out if a char or an
 * element is the last but possibly inadvertently also succeed for an empty
 * string or list, e.g.:
 * ```
 * // For an empty string `indexOf` returns -1 and `length() - 1` is
 * // -1 as well
 * String s = ...;
 * boolean isXLast = s.indexOf('x') == s.length() - 1;
 * ```
 */
 
/*
 * TODO: Not working correctly
 *  - Often a check for a non-empty string or list exists which is guarding this
 *    this check
 *  - In some cases a trailing char / element is treated the same as an empty string
 *    on purpose
 */

import java

predicate isSameVarRead(RValue a, RValue b) {
    a.getVariable() = b.getVariable()
    and 
    (
        // Both read same variable so checking one is enough
        a.getVariable() instanceof LocalScopeVariable
        or a.(FieldRead).getField().isStatic()
        or a.(FieldRead).isOwnFieldAccess() and b.(FieldRead).isOwnFieldAccess()
        or exists (RefType enclosing |
            a.(FieldRead).isEnclosingFieldAccess(enclosing)
            and b.(FieldRead).isEnclosingFieldAccess(enclosing)
        )
        or isSameVarRead(a.getQualifier(), b.getQualifier())
    )
}

class IndexMethodCall extends MethodAccess {
    IndexMethodCall() {
        exists (Method m | m = getMethod().getASourceOverriddenMethod*() |
            (
                m.getDeclaringType() instanceof TypeString
                and m.hasName(["indexOf", "lastIndexOf"])
                and (
                    m.getParameterType(0).hasName("int")
                    or getArgument(0).(StringLiteral).getValue().length() = 1
                )
            )
            or (
                m.getDeclaringType().hasQualifiedName("java.util", "List")
                and m.hasName(["indexOf", "lastIndexOf"])
            )
        )
    }
}

class SizeMethod extends Method {
    SizeMethod() {
        (
            getDeclaringType() instanceof TypeString
            and hasStringSignature("length()")
        )
        or (
            getDeclaringType().hasQualifiedName("java.util", "Collection")
            and hasStringSignature("size()")
        )
    }
}

class SizeMethodCall extends MethodAccess {
    SizeMethodCall() {
        getMethod().getASourceOverriddenMethod*() instanceof SizeMethod
    }
}

// TODO: Too expensive
predicate noWriteBetween(LocalScopeVariable var, Expr a, Expr b) {
    not exists (LValue varWrite | varWrite.getVariable() = var |
        a.getControlFlowNode().getASuccessor+() = varWrite
        and b.getControlFlowNode().getAPredecessor+() = varWrite
    )
}

// TODO: Too expensive
predicate isBetween(Expr expr, Expr a, Expr b) {
    a.getControlFlowNode().getASuccessor+() = expr
    and b.getControlFlowNode().getAPredecessor+() = expr
    or isBetween(expr, b, a)
}

from EQExpr eqExpr, SubExpr sizeMinusOneExpr, IndexMethodCall indexCall, SizeMethodCall sizeCall
where
    sizeMinusOneExpr = eqExpr.getAnOperand()
    and sizeMinusOneExpr.getRightOperand().(IntegerLiteral).getIntValue() = 1
    and (
        // For list subclasses
        (
            indexCall.isOwnMethodAccess()
            and sizeCall.isOwnMethodAccess()
            // And there is no other call between index and size which
            // could change result of one of the calls
            and not exists (MethodAccess call | call.isOwnMethodAccess() |
                isBetween(call, indexCall, sizeCall)
            )
        )
        or (
            isSameVarRead(indexCall.getQualifier(), sizeCall.getQualifier())
            // And there is no other call between index and size which
            // could change result of one of the calls
            and not exists (MethodAccess call |
                isSameVarRead(call.getQualifier(), indexCall.getQualifier())
                and isBetween(call, indexCall, sizeCall)
            )
        )
    )
    // Either index and size calls appear directly in the eqExpr or they are
    // read from a local variable
    and (
        eqExpr.getAnOperand() = indexCall
        or exists (LocalScopeVariable var, VariableAssign varAssign, VarAccess varRead |
            var = varAssign.getDestVar()
            and varAssign.getSource() = indexCall
            and varRead = var.getAnAccess()
        |
            eqExpr.getAnOperand() = varRead
            and noWriteBetween(var, varAssign, varRead)
        )
    )
    and (
        sizeMinusOneExpr.getLeftOperand() = sizeCall
        or exists (LocalScopeVariable var, VariableAssign varAssign, VarAccess varRead |
            var = varAssign.getDestVar()
            and varAssign.getSource() = sizeCall
            and varRead = var.getAnAccess()
        |
            sizeMinusOneExpr.getLeftOperand() = varRead
            and noWriteBetween(var, varAssign, varRead)
        )
    )
select eqExpr
