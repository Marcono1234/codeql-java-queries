/**
 * Finds calls of `Optional.orElse(T)` with `null` as argument, whose result
 * is then later used in a conditional expression (ternary) with a `null` check.
 * E.g.:
 * ```
 * public static String trim(Optional<String> optionalStr) {
 *     String str = optionalStr.orElse(null);
 *     return str == null ? "" : str.trim();
 * }
 * ```
 * This could be simplified using `Optional.map(...)`:
 * ```
 * public static String trim(Optional<String> optionalStr) {
 *     return optionalStr.map(String::trim).orElse("");
 * }
 * ```
 */

import java
import semmle.code.java.dataflow.DataFlow

class TypeOptional extends Class {
    TypeOptional() {
        hasQualifiedName("java.util", "Optional")
    }
}

class OrElseCall extends MethodAccess {
    OrElseCall() {
        exists (Method m | m = getMethod() |
            m.getDeclaringType().getASourceSupertype*() instanceof TypeOptional
            and m.hasName("orElse")
        )
    }
}

class MemberAccess extends Expr {
    Expr qualifier;
    
    MemberAccess() {
        qualifier = this.(FieldAccess).getQualifier()
        or qualifier = this.(Call).getQualifier()
    }
    
    Expr getQualifier() {
        result = qualifier
    }
}

private class NullCheckTernary extends ConditionalExpr {
    Expr nullChecked;
    Expr nonNullExpr;
    
    NullCheckTernary() {
        exists(EqualityTest eqTest, NullLiteral null |
            eqTest = this.getCondition()
            and eqTest.getAnOperand() = null
            and nullChecked = eqTest.getAnOperand()
            and null != nullChecked
            and if eqTest.polarity() = true then nonNullExpr = getFalseExpr()
            else nonNullExpr = getTrueExpr()
        )
    }
    
    Expr getNullChecked() {
        result = nullChecked
    }
    
    Expr getNonNullExpr() {
        result = nonNullExpr
    }
}

from OrElseCall orElseCall, NullCheckTernary nullCheck, VarAccess nullCheckRead, MemberAccess memberAccess
where
    orElseCall.getArgument(0) instanceof NullLiteral
    and nullCheckRead = nullCheck.getNullChecked()
    and memberAccess = nullCheck.getNonNullExpr()
    and DataFlow::localFlow(DataFlow::exprNode(orElseCall), DataFlow::exprNode(nullCheckRead))
    and DataFlow::localFlow(DataFlow::exprNode(orElseCall), DataFlow::exprNode(memberAccess.getQualifier()))
select orElseCall, "Use Optional.map(...).orElse(...) and remove null check $@.", nullCheck, "here"
