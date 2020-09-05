/**
 * Finds array casts with generic type parameter as array component:
 * ```
 * @SuppressWarnings("unchecked")
 * T[] storage = (T[]) new Object[1];
 * ```
 * Unlike classes with generic type parameters where the type argument is not
 * present at runtime due to type erasure, the array component type is present
 * at runtime. Therefore if the user of such an array tries to cast it to a
 * specific type (or the compiler does it implicitly) a ClassCastException occurs.
 *
 * See also https://bugs.openjdk.java.net/browse/JDK-8249950?focusedCommentId=14357191&page=com.atlassian.jira.plugin.system.issuetabpanels%3Acomment-tabpanel#comment-14357191
 */

import java
import semmle.code.java.dataflow.DataFlow

class ArrayNewInstanceMethod extends Method {
    ArrayNewInstanceMethod() {
        getDeclaringType().hasQualifiedName("java.lang.reflect", "Array")
        and hasName("newInstance")
    }
}

class ArraysCopyOfMethod extends Method {
    ArraysCopyOfMethod() {
        getDeclaringType().hasQualifiedName("java.util", "Arrays")
        and hasName(["copyOf", "copyOfRange"])
    }
}

from CastExpr cast
where
    cast.getTypeExpr().(ArrayTypeAccess).getComponentName().getType() instanceof TypeVariable
    // Ignore Array.newInstance / Arrays.copyOf casts assuming that array is created with
    // correct runtime component type
    and not exists (Method m |
        (
            m = cast.getExpr().(MethodAccess).getMethod()
            or exists (MethodAccess call | m = call.getMethod() |
                DataFlow::localFlow(DataFlow::exprNode(call), DataFlow::exprNode(cast.getExpr()))
            )
        )
        and (m instanceof ArrayNewInstanceMethod or m instanceof ArraysCopyOfMethod)
    )
    // Make sure that array is exposed in some way, e.g. as return value or as
    // value of field which is not private
    and (
        exists (ReturnStmt returnStmt |
            not returnStmt.getEnclosingCallable().isPrivate()
            and DataFlow::localFlow(DataFlow::exprNode(cast), DataFlow::exprNode(returnStmt.getResult()))
        )
        or exists (Field f |
            f.getAnAssignedValue() = cast
            and (
                not f.isPrivate()
                or exists (ReturnStmt returnStmt |
                    not returnStmt.getEnclosingCallable().isPrivate()
                    and DataFlow::localFlow(DataFlow::exprNode(f.getAnAccess()), DataFlow::exprNode(returnStmt.getResult()))
                )
            )
        )
    )
select cast