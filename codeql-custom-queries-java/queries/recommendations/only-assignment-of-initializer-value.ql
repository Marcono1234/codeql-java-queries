/**
 * Finds fields or variables for which the only value change is an
 * assignment of the literal value with which the variable was already
 * initialized, so the assignment is pointless.
 */

import java

class IntegralLiteral extends Literal {
    IntegralLiteral() {
        this instanceof IntegerLiteral
        or this instanceof LongLiteral
    }
}

// FloatingPointLiteral would fit better, but QL already choose that for `float`
class FloatLiteral extends Literal {
    FloatLiteral() {
        this instanceof FloatingPointLiteral
        or this instanceof DoubleLiteral
    }
}

// TODO: Does not detect usage of int as char and char as any other numeric type
// (given that code point value is not larger than max value of that type)
// but QL does not offer methods to get code point value? (see https://github.com/github/codeql/issues/3635)
predicate areSameLiterals(Type targetType, Literal a, Literal b) {
    (
        a.getValue() = b.getValue()
        // Check literal types to prevent `false` being considered same
        // as `"false"` and similar cases
        and (
            a.getKind() = b.getKind()
            or (
                a instanceof IntegralLiteral
                and b instanceof IntegralLiteral
            )
            or (
                a instanceof FloatLiteral
                and b instanceof FloatLiteral
            )
        )
    )
    // Allow conversion from integer to float target
    or (
        targetType.(PrimitiveType).getName() in ["float", "double"]
        and (
            a.(FloatLiteral).getValue().toFloat() = b.(IntegralLiteral).getValue().toInt()
            or b.(FloatLiteral).getValue().toFloat() = a.(IntegralLiteral).getValue().toInt()
        )
    )
}

predicate isLiteralSameAsInitializer(Variable var, Literal literal) {
    areSameLiterals(var.getType(), var.getInitializer(), literal)
    or (
        not exists (var.getInitializer())
        and (
            areSameLiterals(var.getType(), var.getType().(PrimitiveType).getADefaultValue(), literal)
            or (
                not var.getType() instanceof PrimitiveType
                and literal instanceof NullLiteral
            )
        )
    )
}

from Variable var, AssignExpr assign
where
    not var.isFinal()
    and not (
        var.(Field).isProtected()
        or var.(Field).isPublic()
    )
    and assign.getDest() = var.getAnAccess()
    and assign.getRhs() != var.getInitializer()
    and isLiteralSameAsInitializer(var, assign.getRhs())
    and not exists (LValue varChange |
        varChange.getVariable() = var
        // varChange does not happen as part of initializer
        and varChange.getParent*() != var.getInitializer().getParent*()
        // varChange is not assignment
        and varChange != assign.getDest()
        // varChange is not itself a pointless assignment
        and not isLiteralSameAsInitializer(var, varChange.getParent().(AssignExpr).getRhs())
    )
select var, assign
