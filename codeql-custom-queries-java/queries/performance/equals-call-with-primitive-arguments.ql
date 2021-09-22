/**
 * Finds calls to `equals(Object)` or `Objects.equals(Object, Object)` where the
 * arguments are of primitive type. These calls should be replaced with usage of
 * the `==` operator to avoid boxing the primitive value.
 */

// Similar to CodeQL's java/implicit-auto-boxing

import java

class PrimitiveExpr extends Expr {
    PrimitiveExpr() {
        getType() instanceof PrimitiveType
    }
}

// Note: This does not check whether boxed and primitive type match, so it
// might find `equals` calls which are always false due to type mismatch
// Converting them to `==` would change behavior

from MethodAccess equalsCall
where
    (
        equalsCall.getMethod() instanceof EqualsMethod
        // Only consider 
        and equalsCall.getReceiverType() instanceof BoxedType
        and equalsCall.getArgument(0) instanceof PrimitiveExpr
    )
    or exists(Method m | m = equalsCall.getMethod() |
        m.getDeclaringType().hasQualifiedName("java.util", "Objects")
        and m.hasStringSignature("equals(Object, Object)")
        // Only consider call when both arguments are primitive; otherwise one
        // of them might be null
        and equalsCall.getArgument(0) instanceof PrimitiveExpr
        and equalsCall.getArgument(1) instanceof PrimitiveExpr
    )
select equalsCall, "Call should be replaced with == operator"
