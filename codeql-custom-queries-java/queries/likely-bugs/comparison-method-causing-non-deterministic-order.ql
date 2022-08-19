/**
 * Finds comparison method implementations such as `Comparable.compareTo` or `Comparator.compare` which
 * return after having only checked the field value of one object, but not of the other one. Such
 * implementations can cause non-deterministic ordering. For example:
 * ```java
 * @Override
 * public int compareTo(MyClass other) {
 *     // Bad: Causes inconsistent order if `other.f` is also null
 *     if (this.f == null) {
 *         return -1;
 *     }
 *     ...
 * }
 * ```
 * Such an implementation violates the `compareTo` contract because when two instances `a` and `b`
 * both have `f == null`, both `a.compareTo(b)` and `b.compareTo(a)` would return -1.
 * The correct implementation would be to check the fields of both objects; if they are the same
 * the next fields have to be checked or 0 has to be returned.
 * 
 * The `java.util.Comparator` interface also provides convenience factory methods which allow comparing
 * fields in a concise and less error-prone way.
 * 
 * @kind problem
 */

// TODO: Make this more accuracte

import java

class ComparableCompareToMethod extends Method {
    ComparableCompareToMethod() {
        getDeclaringType().hasQualifiedName("java.lang", "Comparable")
        and hasName("compareTo")
    }
}

class ComparatorCompareMethod extends Method {
    ComparatorCompareMethod() {
        getDeclaringType().hasQualifiedName("java.util", "Comparator")
        and hasName("compare")
    }
}

class ComparingMethod extends Method {
    ComparingMethod() {
        exists(Method overridden | overridden = getSourceDeclaration().getASourceOverriddenMethod*() |
            overridden instanceof ComparableCompareToMethod
            or overridden instanceof ComparatorCompareMethod
        )
    }
}

VarAccess getACheckingAccess(IfStmt ifStmt) {
    exists(Expr condition |
        condition = ifStmt.getCondition()
        and result.getParent*() = condition
        // Ignore if variable access occurs as qualifier of field
        and not any(FieldAccess fieldAccess | fieldAccess.getParent*() = ifStmt.getCondition()).getQualifier() = result
    )
}

/**
 * Holds if both expressions access the same field or parameters of the same type.
 */
predicate accessSameVariable(RValue a, RValue b) {
    a.(FieldRead).getField() = b.(FieldRead).getField()
    or (
        // Both check the `Comparator.compare` parameters
        a.getVariable() instanceof Parameter
        and b.getVariable() instanceof Parameter
    )
}

from ComparingMethod m, IfStmt ifStmt, VarAccess checkingAccess, ReturnStmt returnStmt
where
    ifStmt.getEnclosingStmt() = m.getBody()
    and checkingAccess = getACheckingAccess(ifStmt)
    // And only one variable is checked
    and not exists(VarAccess other |
        other = getACheckingAccess(ifStmt)
        and checkingAccess != other
        and accessSameVariable(checkingAccess, other)
    )
    // Ignore if check is performed on local variable (might be result of other `compare` call)
    and exists(Variable var | var = checkingAccess.getVariable() |
        var instanceof Parameter
        or var instanceof Field
    )
    // Ignore if parameter is checked for null, or instanceof check is performed
    and not (
        checkingAccess.getVariable() instanceof Parameter
        and (
            ifStmt.getCondition().(EQExpr).getAnOperand() instanceof NullLiteral
            or ifStmt.getCondition().(InstanceOfExpr).getExpr() = checkingAccess
        )
    )
    // And `then` only returns
    and (
        returnStmt = ifStmt.getThen()
        or returnStmt = ifStmt.getThen().(SingletonBlock).getStmt()
    )
    and returnStmt.getResult() instanceof CompileTimeConstantExpr
    // Ignore comparison with `this`
    and not ifStmt.getCondition().getAChildExpr*().(BinaryExpr).getAnOperand() instanceof ThisAccess
    // Ignore if variable has been checked previously already
    and not exists(VarAccess previousAccess |
        previousAccess = checkingAccess.getVariable().getAnAccess()
        and previousAccess.getControlFlowNode().getASuccessor+() = ifStmt
        and accessSameVariable(checkingAccess, previousAccess)
    )
select returnStmt, "Returning here without having checked field of both objects can make ordering non-deterministic"
