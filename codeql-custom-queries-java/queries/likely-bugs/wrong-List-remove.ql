/**
 * `java.util.List` declares two `remove` methods:
 * - `remove(int)`: Remove element at specified index
 * - `remove(Object)`: Remove specified element
 *
 * This query tries to find cases where the wrong method is called by
 * accident:
 * - Calling `List.remove` with an `Integer` removes that element, while
 *   the caller might have wanted to remove the element at that index.
 * - Calling `List<Integer>.remove` with an `int` removes the element at
 *   that index, while the caller might have wanted to remove the boxed element.
 */

import java
import lib.Expressions

class RemoveElementMethod extends Method {
    RemoveElementMethod() {
        getDeclaringType().getErasure().(RefType).hasQualifiedName("java.util", "List")
        and hasStringSignature("remove(Object)")
    }
}

class RemoveAtIndexMethod extends Method {
    RemoveAtIndexMethod() {
        getDeclaringType().getErasure().(RefType).hasQualifiedName("java.util", "List")
        and hasStringSignature("remove(int)")
    }
}

from MethodAccess call, Expr argument
where
    argument = call.getAnArgument()
    // Make sure that return value of call is ignored
    and call instanceof ValueDiscardingExpr
    and (
        // Calling remove(Object) with Integer
        (
            call.getMethod().getAnOverride*() instanceof RemoveElementMethod
            and argument.getType().(RefType).hasQualifiedName("java.lang", "Integer")
        )
        // Calling List<Integer>.remove(int)
        or (
            call.getMethod().getAnOverride*() instanceof RemoveAtIndexMethod
            and call.getReceiverType().getASupertype*().hasQualifiedName("java.util", "List<Integer>")
            and argument.getType().hasName("int")
        )
    )
select call, argument
