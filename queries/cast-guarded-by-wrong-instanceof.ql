/**
 * Finds `instanceof` expressions which appear to guard a cast expression,
 * however that expression casts to a type which is not guaranteed by the
 * `instanceof`.
 */

import java

// Use boolean result instead of predicate to verify that condition node exists
boolean doesInstanceOfVerifyCast(InstanceOfExpr instanceOfExpr, CastExpr cast) {
    exists (ConditionNode conditionNode, Variable var, RefType instanceOfType, Type castType |
        instanceOfExpr = conditionNode.getCondition()
        and instanceOfExpr.getExpr() = var.getAnAccess()
        and instanceOfType = instanceOfExpr.getTypeName().getType().getErasure()
        and cast.getBasicBlock() = conditionNode.getATrueSuccessor()
        and cast.getExpr() = var.getAnAccess()
        and castType = cast.getType().getErasure()
        |
        if (
            /*
             * Using ConditionNode has the disadvantage that it matches the
             * second operand of a logical AND, e.g.:
             * `if (a instanceof A && a instanceof B)`
             * matches for `instanceof B` and would flag any cast to `A` since
             * `instanceof A` on its own is not true.
             * To prevent such false positives, assume that if there is another
             * `instanceof` and both share the same ancestor the cast is safe
             */
            exists (InstanceOfExpr otherInstanceOf |
                otherInstanceOf != instanceOfExpr
                and instanceOfExpr.getParent+() = otherInstanceOf.getParent+()
            )
            // Unwrapping boxed type
            or instanceOfType.(BoxedType).getPrimitiveType() = castType
            // Or numeric conversion
            or (
                instanceOfType.(NumericOrCharType) instanceof BoxedType
                and castType.(NumericOrCharType) instanceof PrimitiveType
            )
            // Casting to super type is safe
            or instanceOfType.getAnAncestor().getErasure() = castType
        ) then result = true else result = false
    )
}

from InstanceOfExpr instanceOfExpr, CastExpr cast
where
    doesInstanceOfVerifyCast(instanceOfExpr, cast) = false
    and not exists (InstanceOfExpr otherInstanceOf |
        otherInstanceOf != instanceOfExpr
        and doesInstanceOfVerifyCast(otherInstanceOf, cast) = true
    )
select instanceOfExpr, cast
