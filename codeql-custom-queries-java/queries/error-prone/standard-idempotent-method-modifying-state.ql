/**
 * Finds implementations of standard idempotent methods, that is methods which when called
 * multiple times with the same arguments should yield the same result, such as `toString()`,
 * `hashCode()`, `equals(Object)` and `Comparable.compareTo(T)` which appear to change the
 * state of the object (or of a different object). This violates the idempotence and can
 * lead to unexpected behavior.
 */

import java

class CompareToMethod extends Method {
    CompareToMethod() {
        hasName("compareTo")
        and getNumberOfParameters() = 1
        and getParameterType(0) instanceof RefType
        and getDeclaringType().getASourceSupertype*().hasQualifiedName("java.lang", "Comparable")
    }
}

from Method standardMethod, Expr stateChangingExpr
where
    (
        standardMethod instanceof ToStringMethod
        or standardMethod instanceof HashCodeMethod
        or standardMethod instanceof EqualsMethod
        or standardMethod instanceof CompareToMethod
    )
    and stateChangingExpr.getEnclosingCallable() = standardMethod
    // TODO: Maybe ignore if state change is performed on local object which has just been created
    // and is only used within method
    and (
        // Changes field value
        exists(Field f, FieldWrite fieldWrite |
            fieldWrite = stateChangingExpr
            and f = fieldWrite.getField()
            // Ignore if field write seems to cache result
            and not (
                // Only relevant for methods without parameters
                standardMethod.hasNoParameters()
                // If there is a field read for the same field, assume it checks if
                // cached result exists
                and exists(FieldRead fieldRead |
                    fieldRead = f.getAnAccess()
                    and fieldRead.getEnclosingCallable() = standardMethod
                    // Ignore compound assignments
                    and fieldRead != fieldWrite
                    and fieldRead.isOwnFieldAccess()
                    and fieldWrite.isOwnFieldAccess()
                )
            )
        )
        // Or changes element of array field
        or exists(ArrayAccess arrayAccess |
            arrayAccess.getArray() instanceof FieldAccess
            and (
                stateChangingExpr.(Assignment).getDest() = arrayAccess
                // Note: Assignment does not include UnaryAssignExpr, see https://github.com/github/codeql/issues/6446
                or stateChangingExpr.(UnaryAssignExpr).getExpr() = arrayAccess
            )
        )
    )
select stateChangingExpr, "Changes state within standard method"
