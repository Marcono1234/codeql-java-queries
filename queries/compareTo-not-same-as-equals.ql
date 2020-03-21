/**
 * Finds classes whose `equals(Object)` and `compareTo(T)` implementations
 * do not check the same fields. This is allowed by the contract of
 * `compareTo`, but should be documented.
 */

import java
import semmle.code.java.dataflow.DataFlow

// From https://github.com/Semmle/ql/blob/9ec52a43eef0aeca4e39fa9021d196e5589cfb9e/java/ql/src/Likely%20Bugs/Comparison/InconsistentCompareTo.ql
predicate implementsComparableOn(RefType t, RefType typeArg) {
    exists(RefType cmp |
        t.getAnAncestor() = cmp
        and cmp.getSourceDeclaration().hasQualifiedName("java.lang", "Comparable")
    |
        // Either `t` extends `Comparable<T>`, in which case `typeArg` is `T`, ...
        typeArg = cmp.(ParameterizedType).getATypeArgument() and not typeArg instanceof Wildcard
        or
        // ... or it extends the raw type `Comparable`, in which case `typeArg` is `Object`.
        cmp instanceof RawType and typeArg instanceof TypeObject
    )
}

class CompareToMethod extends Method {
    CompareToMethod() {
        this.hasName("compareTo")
        and this.isPublic()
        and this.getNumberOfParameters() = 1
        // To implement `Comparable<T>.compareTo`, the parameter must either have type `T` or `Object`.
        and exists(RefType typeArg, Type firstParamType |
            implementsComparableOn(this.getDeclaringType(), typeArg)
            and firstParamType = getParameter(0).getType()
            and (firstParamType = typeArg or firstParamType instanceof TypeObject)
        )
    }
}

predicate delegatesCheck(Method m) {
    exists (MethodAccess call | 
        DataFlow::localFlow(DataFlow::parameterNode(m.getAParameter()), DataFlow::exprNode(call.getAnArgument()))
    )
}

from Field f, Method equalsM, CompareToMethod compareToM
where
    equalsM.hasStringSignature("equals(Object)")
    and equalsM.getDeclaringType() = compareToM.getDeclaringType()
    // Check that field is declared by same type (or its ancestor)
    and equalsM.getDeclaringType().getAnAncestor() = f.getDeclaringType()
    // Ignore static fields because they likely do not influence equality check
    and not f.isStatic()
    // Check if field is only read by one of the methods
    and (
        (equalsM.reads(f) and not compareToM.reads(f))
        or (not equalsM.reads(f) and compareToM.reads(f))
	)
    // Verify that equality check is not delegated
    and not (delegatesCheck(equalsM) or delegatesCheck(compareToM))
select equalsM, compareToM, f
