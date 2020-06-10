/**
 * Finds usages of `String.split(String)` and `Pattern.split​(CharSequence)`
 * where the caller only expects at least a certain number of elements
 * but does not care about more elements, e.g.:
 * ```
 * String firstName = name.split(" ")[0];
 * ```
 * The `split` method with a _limit_ parameter should be preferred since
 * otherwise the regex unnecessarily yields unused results which increases
 * execution time and used memory.
 */

import java

class SplitMethod extends Method {
    SplitMethod() {
        (
            getDeclaringType().hasQualifiedName("java.lang", "String")
            and hasStringSignature("split(String)")
        )
        or (
            getDeclaringType().hasQualifiedName("java.util.regex", "Pattern")
            and hasStringSignature("split(CharSequence)")
        )
    }
}

// Assignment does not cover local var declaration
// See https://github.com/github/codeql/issues/3266
class VarAssignment extends Expr {
    VarAssignment() {
        // Ignore assignments whose result is used, e.g. test(a = s.split(","))
        this.(Assignment).getParent() instanceof ExprStmt
        or this instanceof LocalVariableDeclExpr
    }
    
    Variable getVariable() {
        result.getAnAccess() = this.(Assignment).getDest()
        or result = this.(LocalVariableDeclExpr).getVariable()
    }
    
    Expr getRhs() {
        result = this.(Assignment).getRhs()
        or result = this.(LocalVariableDeclExpr).getInit()
    }
}

class CompileTimeIndexArrayAccess extends ArrayAccess {
    CompileTimeIndexArrayAccess() {
        getIndexExpr() instanceof CompileTimeConstantExpr
    }
}

predicate hasKnownNumberOfArrayElements(MethodAccess splitCall) {
    // Array access with constant index happens on result
    splitCall.getParent() instanceof CompileTimeIndexArrayAccess
    // Or result is assigned to variable and then only array access
    // with constant indices occurs
    or exists (VarAssignment varAssignment, LocalScopeVariable var |
        var = varAssignment.getVariable()
        and varAssignment.getRhs() = splitCall
        and forall (ExprParent other |
            other != varAssignment
            and other = var.getAnAccess().getParent()
            |
            other instanceof CompileTimeIndexArrayAccess
        )
    )
}

from MethodAccess call
where
    call.getMethod() instanceof SplitMethod
    and hasKnownNumberOfArrayElements(call)
select call
