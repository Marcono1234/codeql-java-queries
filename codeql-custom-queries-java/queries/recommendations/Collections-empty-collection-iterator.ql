/**
 * Finds code which creates an empty `Iterator` or `ListIterator` by first obtaining
 * an empty collection from the `Collections` class and then creating an iterator
 * for it. Such code can be simplified by directly using `emptyIterator()` or
 * `emptyListIterator()`.
 * 
 * @kind problem
 */

import java

class TypeCollections extends Class {
    TypeCollections() {
        hasQualifiedName("java.util", "Collections")
    }
}

from Expr emptyCollectionExpr, MethodAccess iteratorCall, string alternative
where
    (
        exists(Field emptyCollectionConstant |
            emptyCollectionConstant = emptyCollectionExpr.(FieldRead).getField()
            and emptyCollectionConstant.getDeclaringType() instanceof TypeCollections
            and emptyCollectionConstant.hasName(["EMPTY_LIST", "EMPTY_SET"])
        )
        or exists(Method emptyCollectionMethod |
            emptyCollectionMethod = emptyCollectionExpr.(MethodAccess).getMethod().getSourceDeclaration()
            and emptyCollectionMethod.getDeclaringType() instanceof TypeCollections
            and emptyCollectionMethod.hasName(["emptyList", "emptySet"])
        )
    )
    and iteratorCall.getQualifier() = emptyCollectionExpr
    and exists(string methodSignature |
        methodSignature = iteratorCall.getMethod().getSourceDeclaration().getStringSignature()
    |
        methodSignature = "iterator()" and alternative = "emptyIterator"
        or methodSignature = "listIterator()" and alternative = "emptyListIterator"
    )
select iteratorCall, "Could instead use Collections." + alternative + "()"
