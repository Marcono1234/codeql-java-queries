/**
 * Finds `hashCode()` implementations which consider more fields than
 * `equals(Object)` or `compareTo(T)` does. This can result in different
 * hash codes despite `equals` / `compareTo` claiming that the objects
 * are equal, which violates the requirements.
 */

import java

// From https://github.com/Semmle/ql/blob/9ec52a43eef0aeca4e39fa9021d196e5589cfb9e/java/ql/src/Likely%20Bugs/Comparison/InconsistentCompareTo.ql
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

from Field f, Method equalityM, Method hashCodeM
where
    isEqualityMethod(equalityM)
    and hashCodeM.hasStringSignature("hashCode()")
    and equalityM.getDeclaringType() = hashCodeM.getDeclaringType()
    // Check that field is declared by same type (or its ancestor)
    and equalityM.getDeclaringType().getAnAncestor() = f.getDeclaringType()
    // Ignore static fields because they influence hashCode for all instances
    // in the same way
    and not f.isStatic()
    // Check if hashCode considers field, but equals does not
    and hashCodeM.reads(f) and not equalityM.reads(f)
    // Verify that equals does not delegate check by calling another method with `obj`
    and not delegatesCheck(equalityM)
select hashCodeM, equalityM, f
