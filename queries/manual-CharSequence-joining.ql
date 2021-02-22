/**
 * Finds `for` loops which are manually joining `CharSequence` elements
 * to create a result String consisting of the elements.
 * The JDK provides several classes and methods which allow efficient
 * (and less error-prone) joining of CharSequences, these classes and
 * methods should be preferred:
 * - [`String.join(...)`](https://docs.oracle.com/en/java/javase/15/docs/api/java.base/java/lang/String.html#join(java.lang.CharSequence,java.lang.CharSequence...))
 * - [`StringJoiner`](https://docs.oracle.com/en/java/javase/15/docs/api/java.base/java/util/StringJoiner.html)
 * - [`Collectors.joining(...)`](https://docs.oracle.com/en/java/javase/15/docs/api/java.base/java/util/stream/Collectors.html#joining(java.lang.CharSequence))
 */

import java

class StringAppendingMethod extends Method {
    StringAppendingMethod() {
        (
            getDeclaringType() instanceof TypeStringBuilder
            or getDeclaringType() instanceof TypeStringBuffer
        )
        and hasName("append")
    }
}

class TypeCharSequence extends Interface {
    TypeCharSequence() {
        hasQualifiedName("java.lang", "CharSequence")
    }
}

private Expr getAStringJoiningExpr(Variable localVar) {
    exists(VarAccess varRead | varRead = localVar.getAnAccess() |
        // var = var + localVar
        exists(Variable resultVar, AssignExpr assign, AddExpr concatExpr |
            resultVar.getType() instanceof TypeString
            // Ignore if localVar is prefixed / suffixed, but there is no joining
            and resultVar != localVar
            and result = assign
            and concatExpr.getType() instanceof TypeString
            and concatExpr.getParent*() = assign.getRhs()
        |
            assign.getDest() = resultVar.getAnAccess()
            and resultVar.getAnAccess().getParent+() = concatExpr
            and varRead.getParent+() = concatExpr
        )
        // var += localVar
        or exists(AssignAddExpr concatAddExpr |
            concatAddExpr = result
            and concatAddExpr.getDest().getType() instanceof TypeString
            and varRead.getParent*() = concatAddExpr.getRhs()
        )
        // sb.append(localVar)
        or exists(MethodAccess appendCall | result = appendCall |
            appendCall.getMethod() instanceof StringAppendingMethod
            and appendCall.getAnArgument() = varRead
        )
    )
}

private Stmt getNonBlockEnclosingStmt(Stmt s) {
    result = s.getEnclosingStmt() and not result instanceof BlockStmt
    or result = getNonBlockEnclosingStmt(s.getEnclosingStmt().(BlockStmt))
}

from EnhancedForStmt forStmt, Variable joinedVar, Expr joiningExpr
where
    joinedVar = forStmt.getVariable().getVariable()
    and joinedVar.getType().(RefType).getASourceSupertype*() instanceof TypeCharSequence
    // Make sure that forBody is not complex and StringJoiner is actually an alternative
    and exists(Stmt forBody | forBody = forStmt.getStmt() |
        // for statement does not have block body; ExprStmt is body
        joiningExpr.getEnclosingStmt() = forBody
        // Either directly inside body
        or joiningExpr.getEnclosingStmt().getEnclosingStmt() = forBody.(BlockStmt)
        // Or body only has very few statements (e.g. `if`) and expression is inside that one
        or exists(Stmt parent |
            parent = getNonBlockEnclosingStmt(joiningExpr.getEnclosingStmt())
            and parent.getEnclosingStmt() = forBody.(BlockStmt)
            and forBody.(BlockStmt).getNumStmt() <= 2
        )
    )
    and joiningExpr = getAStringJoiningExpr(joinedVar)
select joiningExpr, "Joins CharSequences manually"
