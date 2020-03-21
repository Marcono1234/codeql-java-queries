/**
 * For efficiency `equals(Object)` and `compareTo(T)` implementations
 * should start by checking if `obj == this`.
 * This query finds implementations which do not do this.
 */

import java

/// From https://github.com/Semmle/ql/blob/9ec52a43eef0aeca4e39fa9021d196e5589cfb9e/java/ql/src/Likely%20Bugs/Comparison/InconsistentCompareTo.ql
predicate implementsComparableOn(RefType t, RefType typeArg) {
    exists(RefType cmp |
        t.getAnAncestor() = cmp and
        cmp.getSourceDeclaration().hasQualifiedName("java.lang", "Comparable")
    |
        // Either `t` extends `Comparable<T>`, in which case `typeArg` is `T`, ...
        typeArg = cmp.(ParameterizedType).getATypeArgument() and not typeArg instanceof Wildcard
        or
        // ... or it extends the raw type `Comparable`, in which case `typeArg` is `Object`.
        cmp instanceof RawType and typeArg instanceof TypeObject
    )
}

predicate isEqualityMethod(Method m) {
    m.hasStringSignature("equals(Object)")
    or (
    m.hasName("compareTo")
    and m.getNumberOfParameters() = 1
    // To implement `Comparable<T>.compareTo`, the parameter must either have type `T` or `Object`.
    and exists(RefType typeArg, Type firstParamType |
        implementsComparableOn(m.getDeclaringType(), typeArg)
        and firstParamType = m.getParameter(0).getType()
        and (firstParamType = typeArg or firstParamType instanceof TypeObject)
    )
  )
}

predicate delegatesCheck(Method m) {
    exists (MethodAccess call | 
        call.getAnArgument().(RValue).getVariable() = m.getAParameter()
    )
}

from Method method
where
    isEqualityMethod(method)
    // Make sure that equality check is not delegated
    and delegatesCheck(method)
    // Check if no equality check containing `this` and `obj` exists
    and not exists(EqualityTest eq |
        eq.getAnOperand().(RValue).getVariable() = method.getAParameter()
        and eq.getAnOperand() instanceof ThisAccess
    )
select method
