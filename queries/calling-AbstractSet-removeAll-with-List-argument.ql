/**
 * Finds `AbstractSet.removeAll(...)` calls with a `List` as argument.
 * The default implementation of `removeAll(...)` iterates over the given
 * `Collection` argument if it is equal to or bigger than the set, and
 * checks whether the `Collection` contains the set elements.
 * Therefore if the argument is of type `List` the complexity can become
 * up to _O(n)_ instead of _O(1)_ for each element to remove.
 *
 * A workaround is to manually iterate over the `Collection` of elements
 * to remove and remove them one by one.
 *
 * See:
 *  - https://codeblog.jonskeet.uk/2010/07/29/there-s-a-hole-in-my-abstraction-dear-liza-dear-liza/
 *  - https://bugs.openjdk.java.net/browse/JDK-6394757
 */

import java

class RemoveAllMethod extends Method {
    RemoveAllMethod() {
        getDeclaringType().getASourceSupertype*().hasQualifiedName("java.util", "Collection")
        and hasStringSignature("removeAll(Collection<?>)")
    }
}

class TypeAbstractSet extends RefType {
    TypeAbstractSet() {
        getASourceSupertype*().hasQualifiedName("java.util", "AbstractSet")
    }
}

class TypeList extends RefType {
    TypeList() {
        getASourceSupertype*().hasQualifiedName("java.util", "List")
    }
}

RefType getType(Expr expr) {
    result = expr.getType()
    or exists (LocalScopeVariable var |
        expr = var.getAnAccess()
        and result = var.getAnAssignedValue().getType()
    )
}

from MethodAccess removeAllCall
where
    removeAllCall.getMethod() instanceof RemoveAllMethod
    and getType(removeAllCall.getQualifier()) instanceof TypeAbstractSet
    and getType(removeAllCall.getArgument(0)) instanceof TypeList
select removeAllCall, "Calls AbstractSet.removeAll(...) with a List as argument"
