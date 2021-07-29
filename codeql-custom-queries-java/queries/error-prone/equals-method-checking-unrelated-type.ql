/**
 * Finds `equals(Object)` implementations which check whether the given argument is
 * of a certain type, which is unrelated to the type of the implementing class.
 * Such an implementation is most likely not symmetric: `this.equals(other)` is
 * true, but `other.equals(this)` is not. This should be avoided because it can
 * cause unexpected behavior, for example when used as elements of collections.
 * 
 * This query is similar to CodeQL's query `java/instanceof-in-equals`.
 */

// Similar to SpotBugs `EQ_CHECK_FOR_OPERAND_NOT_COMPATIBLE_WITH_THIS`

import java

Type getTypeCheckedByInstanceOfExpr(InstanceOfExpr e, Variable checked) {
    e.getExpr() = checked.getAnAccess()
    and result = e.getCheckedType()
}

Type getTypeCheckedByEqualityTest(EQExpr e, Variable checked) {
    exists(MethodAccess getClassCall |
        getClassCall.getMethod().hasStringSignature("getClass()")
    |
        e.getAnOperand() = getClassCall
        and getClassCall.getQualifier() = checked.getAnAccess()
        and result = e.getAnOperand().(TypeLiteral).getReferencedType()
    )
}

Type getSourceType(Type t) {
    if (t instanceof RefType) then result = t.(RefType).getSourceDeclaration()
    else result = t
}

from EqualsMethod equalsMethod, Parameter checkedParam, Expr typeCheck, Type checkedType
where
    checkedParam = equalsMethod.getParameter()
    and typeCheck.getEnclosingCallable() = equalsMethod
    and checkedType = getSourceType([
        getTypeCheckedByInstanceOfExpr(typeCheck, checkedParam),
        getTypeCheckedByEqualityTest(typeCheck, checkedParam)
    ])
    // Checked type is unrelated
    and not checkedType = equalsMethod.getDeclaringType().getASourceSupertype*()
    // Ignore if check is for subtype of declaring type; should possibly use inheritance then instead
    // but that should be detected by a separate query
    and not checkedType.(RefType).getSourceDeclaration().getASourceSupertype*() = equalsMethod.getDeclaringType()
select equalsMethod, "Checks $@ for unrelated type $@", typeCheck, "here", checkedType, checkedType.getName()
