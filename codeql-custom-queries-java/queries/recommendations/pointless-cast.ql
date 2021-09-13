/**
 * Finds cast expressions which cast an expression to the same or a supertype.
 * Such cast expressions are pointless and can be omitted.
 */

// TODO Remove? Seems to be the same as CodeQL's java/useless-upcast

import java

RefType getAnAcestor(RefType t) {
    // Get a supertype but ignore if it has the same source declaration, e.g. ignore raw type
    (result = t.getASupertype() and result.getSourceDeclaration() != t.getSourceDeclaration())
    or result = getAnAcestor(t.getASupertype().getSourceDeclaration())
}

predicate isOverload(Call call, Callable callee, Callable overload) {
    callee.getNumberOfParameters() = overload.getNumberOfParameters()
    and callee.getSourceDeclaration() != overload.getSourceDeclaration()
    and (
        callee.(Constructor).getDeclaringType() = overload.(Constructor).getDeclaringType()
        or (
            callee.(Method).getName() = overload.(Method).getName()
            and call.(MethodAccess).getReceiverType().inherits(overload)
        )
    )
}

predicate hasTypeVariable(RefType t) {
    t instanceof TypeVariable
    or hasTypeVariable(t.(ParameterizedType).getATypeArgument())
    or hasTypeVariable(t.(Array).getElementType())
}

predicate isArgForTypeVariableParam(Expr e) {
    exists(Call call, Parameter param |
        call.getAnArgument() = e
        and call.getCallee().getSourceDeclaration().getAParameter() = param
    |
        param.getAnArgument() = e
        and hasTypeVariable(param.getType())
        or
        param.isVarargs() and e.(Argument).isVararg()
        and hasTypeVariable(param.getType().(Array).getElementType())
    )
}

/*
 * Note: Don't consider java.lang.Class.cast(...) since there the runtime type might
 * be more specific than the compile-time type, except when using a type literal,
 * but using type literal for calling `cast` should be covered by separate query
 */


// TODO: Also consider widening primitive type casts?

from CastExpr castExpr, Expr expr
where
    expr = castExpr.getExpr()
    and castExpr.getType() = [expr.getType(), getAnAcestor(expr.getType())]
    // Ignore casting lambda or method reference expression since there the cast is necessary
    and not expr instanceof FunctionalExpr
    // Ignore if cast is used to get correct overload
    and not exists(Call call, Callable callee |
        call.getAnArgument() = castExpr
        and callee = call.getCallee()
    |
        isOverload(call, callee, _)
    )
    // Ignore if cast is used to access shadowed field
    and not exists(FieldAccess fieldAccess, Field accessedField, Field shadowedField |
        fieldAccess.getQualifier() = castExpr
        and accessedField = fieldAccess.getField()
        and shadowedField != accessedField
    |
        expr.getType().(RefType).inherits(shadowedField)
        and shadowedField.getName() = accessedField.getName()
    )
    // Ignore if argument to method with type variable as parameter type
    // In this case cast expression might be used to influence type inference
    and not isArgForTypeVariableParam(castExpr)
select castExpr, "Performs pointless cast to same type or supertype"
