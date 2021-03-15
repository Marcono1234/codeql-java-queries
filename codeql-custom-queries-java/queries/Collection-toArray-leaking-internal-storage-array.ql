/**
 * Finds implementations of one of the `java.util.Collection.toArray`
 * methods which appear to not create a new array or use the array
 * provided as argument but instead leak the internal storage array.
 */

import java
import semmle.code.java.dataflow.DataFlow

class ToArrayMethod extends Method {
    ToArrayMethod() {
        getDeclaringType().hasQualifiedName("java.util", "Collection")
        and hasName("toArray")
    }
}

from Method toArrayOverride, Field instanceField, ReturnStmt returnStmt
where
    toArrayOverride.getASourceOverriddenMethod*() instanceof ToArrayMethod
    and not instanceField.isStatic()
    and returnStmt.getEnclosingCallable() = toArrayOverride
    and exists (FieldAccess fieldAccess |
        fieldAccess = instanceField.getAnAccess()
        and (
            fieldAccess.isOwnFieldAccess()
            or fieldAccess.isEnclosingFieldAccess(_)
        )
    |
        DataFlow::localFlow(DataFlow::exprNode(fieldAccess), DataFlow::exprNode(returnStmt.getResult()))
    )
select returnStmt
