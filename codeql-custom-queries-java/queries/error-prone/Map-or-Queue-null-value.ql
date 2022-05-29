/**
 * Finds code which adds `null` to a `Map` or a `Queue`. This can be error-prone because
 * both classes offer methods which also use `null` to indicate 'no value', for example
 * `Map.get(K)` or `Queue.poll()`. Using `null` can therefore can lead to inconsistent
 * and incorrect results, depending on which methods of these classes are used.
 */

import java
import semmle.code.java.dataflow.Nullness
import semmle.code.java.dataflow.NullGuards

class MapPutMethod extends Method {
    private int valueParamIndex;

    MapPutMethod() {
        getDeclaringType().hasQualifiedName("java.util", "Map")
        and (
            hasName(["put", "putIfAbsent"])
            and valueParamIndex = 1
            or
            hasName("replace") and getNumberOfParameters() = 2
            and valueParamIndex = 1
            or
            hasName("replace") and getNumberOfParameters() = 3
            and valueParamIndex = 2

        )
    }

    int getValueParamIndex() {
        result = valueParamIndex
    }
}

class QueueAddMethod extends Method {
    QueueAddMethod() {
        getDeclaringType().hasQualifiedName("java.util", ["Queue", "Deque"])
        // Covers Queue and Deque methods
        and hasName(["add", "addFirst", "addLast", "offer", "offerFirst", "offerLast", "push"])
    }

    int getValueParamIndex() {
        result = 0
    }
}

from MethodAccess addCall, Expr nullExpr, string typeName
where
    exists(Method overriddenMethod |
        overriddenMethod = addCall.getMethod().getSourceDeclaration().getASourceOverriddenMethod*()
    |
        exists(MapPutMethod mapPutMethod |
            mapPutMethod = overriddenMethod
            and addCall.getArgument(mapPutMethod.getValueParamIndex()) = nullExpr
            and typeName = "Map"
        )
        or exists(QueueAddMethod queueAddMethod |
            queueAddMethod = overriddenMethod
            and addCall.getArgument(queueAddMethod.getValueParamIndex()) = nullExpr
            and typeName = "Queue"
        )
    )
    and (
        nullExpr = alwaysNullExpr()
        or alwaysNullDeref(_, nullExpr)
    )
select nullExpr, "Adds null to a " + typeName
