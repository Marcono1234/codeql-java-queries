/**
 * Finds calls to `Hashtable.contains(Object)` and `ConcurrentHashMap.contains(Object)`.
 * To make the code easier to understand these calls should be replaced with
 * calls to `Map.containsValue(Object)`, which behaves exactly the same but
 * whose method name is more expressive.
 */

import java

class MapContainsMethod extends Method {
    MapContainsMethod() {
        exists(RefType t | t = getDeclaringType().getASourceSupertype*() |
            t.hasQualifiedName("java.util", "Hashtable")
            or t.hasQualifiedName("java.util.concurrent", "ConcurrentHashMap")
        )
        and hasStringSignature("contains(Object)")
    }
}

class MapContainsValueMethod extends Method {
    MapContainsValueMethod() {
        getDeclaringType().getASourceSupertype*().hasQualifiedName("java.util", "Map")
        and hasStringSignature("containsValue(Object)")
    }
}
from MethodAccess containsCall
where
    containsCall.getMethod() instanceof MapContainsMethod
    // Ignore if call happens inside `contains(Object)` or `containsValue(Object)` and
    // just delegates to `contains(Object)` (e.g. of parent or other object)
    and not (
        containsCall.getEnclosingCallable() instanceof MapContainsMethod
        or containsCall.getEnclosingCallable() instanceof MapContainsValueMethod
    )
select containsCall, "Should use Map.containsValue(...) instead"
