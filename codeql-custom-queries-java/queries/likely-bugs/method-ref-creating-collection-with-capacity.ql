/**
 * Finds method reference expressions which might by accident refer to collection constructors
 * or factory methods which take an `int` as capacity argument. The method reference expression
 * might have been intended to just create a new collection, and the argument is accidentally
 * misinterpreted as capacity.
 * 
 * If usage of the referenced constructor or method with capacity parameter is intended, the code
 * should be rewritten as lambda expression to make this explicit. For example:
 * ```java
 * Map<Integer, List<String>> map = ...;
 * // Actually calls `new ArrayList<>(capacity)`
 * map.computeIfAbsent(1, ArrayList::new);
 * 
 * // If that is intended, it should be written like this:
 * map.computeIfAbsent(1, capacity -> new ArrayList<>(capacity));
 * // Or otherwise the argument should be ignored:
 * map.computeIfAbsent(1, key -> new ArrayList<>());
 * ```
 * 
 * Based on [Java Collections Puzzlers by Maurice Naftalin And José Paumard](https://youtu.be/w6hhjg_gt_M?t=1873).
 * 
 * @kind problem
 */

import java

from MethodAccess enclosingCall, MemberRefExpr methodRef, Callable referencedCallable
where
    // To reduce false positives only consider method ref which is argument to an instance method call (e.g. `Map.computeIfAbsent`)
    enclosingCall.getAnArgument() = methodRef
    and not enclosingCall.getMethod().isStatic()
    and methodRef.getReferencedCallable() = referencedCallable
    and (
        referencedCallable instanceof Constructor
        // By convention Collection and Map implementations often have constructor which takes an `int` initial capacity
        and referencedCallable.getDeclaringType().getSourceDeclaration().getASourceSupertype*().hasQualifiedName("java.util", ["Collection", "Map"])
        or
        // Or static factory methods which create collection or map with capacity
        // TODO: Maybe remove this again if it causes too many false positives; though from the method names alone, it is
        //   not immediately obvious that they take a capacity argument
        referencedCallable.(Method).isStatic()
        and exists(string type, string methodName |
            referencedCallable.getDeclaringType().getQualifiedName() = type
            and referencedCallable.hasName(methodName)
        |
            type = "java.util.concurrent.ConcurrentHashMap" and methodName = "newKeySet"
            or type = "java.util.HashMap" and methodName = "newHashMap"
            or type = "java.util.HashSet" and methodName = "newHashSet"
            or type = "java.util.WeakHashMap" and methodName = "newWeakHashMap"
            or type = "java.util.LinkedHashMap" and methodName = "newLinkedHashMap"
            or type = "java.util.LinkedHashSet" and methodName = "newLinkedHashSet"
        )
    )
    and referencedCallable.getNumberOfParameters() = 1
    and referencedCallable.getParameterType(0).(PrimitiveType).hasName("int")
select methodRef, "Might by accident create collection with certain capacity"
