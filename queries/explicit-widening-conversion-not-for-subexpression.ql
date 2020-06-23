/**
 * Finds arithmetic expressions which apparently intend to perform
 * a widening conversion to `long`, but do not perform this on some
 * of their subexpressions which therefore calculate with `int`s
 * and could overflow.
 *
 * Note that in parts this is similar to QL's built-in
 * `java/integer-multiplication-cast-to-long` query which has some
 * overlap with this query.
 */

import java
import semmle.code.java.arithmetic.Overflow

class OverflowingExpr extends BinaryExpr {
    OverflowingExpr() {
        (
            this instanceof AddExpr
            or this instanceof SubExpr
            or this instanceof MulExpr
        )
        and exists (Expr a, Expr b, int widthRankA, Variable var |
            a = getAnOperand()
            and b = getAnOperand()
            and a != b
            |
            a = var.getAnAccess()
            // Make sure var can have an arbitrary value and is not restricted
            // to specific compile-time constant value
            and (
                var instanceof Parameter
                or exists (LocalVariableDeclExpr declExpr |
                    declExpr.getVariable() = var
                    and (
                        declExpr.hasImplicitInit()
                        // Check for non-compile-time constant init (because subsequent Assignment
                        // check does not cover LocalVariableDeclExpr, see https://github.com/github/codeql/issues/3266)
                        or exists (Expr varInit | varInit = declExpr.getInit() |
                            not varInit.isCompileTimeConstant()
                        )
                    )
                )
                or exists (Assignment varAssignment |
                    a = var.getAnAccess()
                    and varAssignment.getDest() = var.getAnAccess()
                    and not varAssignment.getRhs().isCompileTimeConstant()
                )
            )
            and widthRankA = var.getType().(NumType).getWidthRank()
            and widthRankA < 4 // < long
            and b.getType().(NumType).getWidthRank() <= widthRankA
        )
    }
}

class ArithmeticExpr extends Expr {
    ArithmeticExpr() {
        this instanceof AddExpr
        or this instanceof SubExpr
        or this instanceof MulExpr
        or this instanceof DivExpr
        or this instanceof RemExpr
        or this instanceof MinusExpr
        or this instanceof PlusExpr
        or this instanceof UnaryAssignExpr
        // Consider cast as well since it might be used
        // for conversion of numeric types
        or this.(CastExpr).getTypeExpr().getType() instanceof NumType
    }
}

bindingset[checkAncestors]
predicate existsAmbiguousOverload(RefType receiverType, Callable callable, int paramIndex, Type argType, boolean checkAncestors) {
    exists (Callable other |
        other != callable
        and if checkAncestors = true then (
            other.getDeclaringType() = receiverType.getAnAncestor()
        ) else (
            other.getDeclaringType() = receiverType
        )
        and other.getName() = callable.getName()
        and other.getNumberOfParameters() = callable.getNumberOfParameters()
        // All parameters other than parameter at paramIndex are the same
        and forall (int otherParamIndex, Type paramType | otherParamIndex != paramIndex and paramType = other.getParameterType(otherParamIndex) |
            paramType = callable.getParameterType(otherParamIndex)
        )
        // And parameter type at paramIndex matches argType (i.e. type to which cast is applied)
        // Therefore cast is necessary to choose correct overload
        and (
            other.getParameterType(paramIndex) = argType
            or other.getParameterType(paramIndex) = argType.(RefType).getAnAncestor()
        )
    )
}

class ExplicitlyWideningExpr extends Expr {
    ExplicitlyWideningExpr() {
        // `long` literal whose value fits in `int` range suggests an intended widening
        // conversion
        exists (string longLiteral |
            longLiteral = this.(BinaryExpr).getAnOperand().(LongLiteral).getLiteral()
            // Use prefix(length - 1) to remove trailing `L`
            // Remove `_` because QL cannot parse as int otherwise
            // Binary, octal and hexadecimal cannot be parsed either, but normally they are
            // used for bitmasks and not numbers for arithmetic expressions
            and exists (longLiteral.prefix(longLiteral.length() - 1).replaceAll("_", "").toInt())
        )
        // Or cast to `long`; do not consider casts to other types (e.g. `int` or `short`)
        // since result of arithmetic expression in Java is `int`
        or (
            this.(CastExpr).getTypeExpr().getType().(NumType).getOrdPrimitiveType().hasName("long")
            // Make sure cast is not used to choose correct callable overload
            and not exists (Call call, Callable callable, int argIndex |
                callable = call.getCallee()
                and this = call.getArgument(argIndex)
                and if callable instanceof Constructor then (
                    existsAmbiguousOverload(callable.getDeclaringType(), callable, argIndex, this.(CastExpr).getExpr().getType(), false)
                ) else (
                    existsAmbiguousOverload(call.(MethodAccess).getReceiverType(), callable, argIndex, this.(CastExpr).getExpr().getType(), true)
                )
            )
            // Make sure cast is not used to narrow down from floating point type
            and not this.(CastExpr).getExpr().getType().(NumType).getWidthRank() > 4 // > long
        )
    }
}

ArithmeticExpr getArithmeticParent(Expr expr) {
    result = expr.getParent()
}

from OverflowingExpr overflowingExpr, ExplicitlyWideningExpr wideningExpr
where
    getArithmeticParent+(overflowingExpr) = wideningExpr
select overflowingExpr
