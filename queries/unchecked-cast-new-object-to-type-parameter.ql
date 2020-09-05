/**
 * Finds cast expressions which cast a newly created object to a generic
 * type parameter:
 * ```
 * (T) new MyClass()
 * ```
 * Unless this cast is guarded by an exact class check the cast is not
 * safe and could lead to ClassCastExceptions.
 */

import java
import semmle.code.java.dataflow.DataFlow

class IsAssignableFromMethod extends Method {
    IsAssignableFromMethod() {
        getDeclaringType().hasQualifiedName("java.lang", "Class")
        and hasName("isAssignableFrom")
    }
}

predicate checksForType(Expr condition, Type type, boolean isEqual) {
    exists (TypeLiteral typeLiteral | typeLiteral.getType() = type |
        exists (EqualityTest eqTest | eqTest = condition |
            eqTest.getAnOperand() = typeLiteral
            and eqTest.polarity() = isEqual
        )
        or isEqual = true and exists (MethodAccess equalsCall |
            equalsCall = condition
            and equalsCall.getMethod() instanceof EqualsMethod
        |
            equalsCall.getQualifier() = typeLiteral
            or equalsCall.getArgument(0) = typeLiteral
        )
        or isEqual = true and exists (MethodAccess assignableFromCall |
            assignableFromCall = condition
            and assignableFromCall.getMethod() instanceof IsAssignableFromMethod
        |
            // `isAssignableFrom` call checking whether constructed type (call argument)
            // is a subtype of requested type (qualifier)
            assignableFromCall.getArgument(0) = typeLiteral
        )
    )
}

from CastExpr cast, ClassInstanceExpr newExpr
where
    cast.getTypeExpr().(TypeAccess).getType() instanceof TypeVariable
    and cast.getExpr() = newExpr
    // Ignore if cast is guarded by a Class check
    and not exists (ConditionNode node, boolean isEqual |
        node.getABranchSuccessor(isEqual).getASuccessor*() = cast
        and checksForType(node.getCondition(), newExpr.getConstructedType(), isEqual)
    )
select cast
