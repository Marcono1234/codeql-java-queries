import java
import semmle.code.java.dataflow.DataFlow

import lib.Expressions

/**
 * The interface `java.util.Collection`.
 */
class TypeCollection extends Interface {
    TypeCollection() {
        hasQualifiedName("java.util", "Collection")
    }
}

/**
 * The interface `java.util.Set`.
 */
class TypeSet extends Interface {
    TypeSet() {
        hasQualifiedName("java.util", "Set")
    }
}

/**
 * `Set` subtype which preserves the insertion order.
 */
class InsertionOrderSetType extends RefType {
    InsertionOrderSetType() {
        hasQualifiedName("java.util", "LinkedHashSet")
        or hasQualifiedName("java.util.concurrent", "CopyOnWriteArraySet")
    }
}

/**
 * `Set` subtype which orders its elements in some consistent way.
 */
class OrderedSetType extends RefType {
    OrderedSetType() {
        this instanceof InsertionOrderSetType
        or hasQualifiedName("java.util", [
            "EnumSet",
            "SortedSet",
        ])
    }
}

/**
 * Holds if the expression represents access to a collection over which a
 * (possibly indirect) iteration is performed which preserves the order
 * of the elements.
 * 
 * If `includeSynchronized` is `true` this includes methods which might
 * synchronize on the collection.
 */
bindingset[includeSynchronized]
predicate isOrderPreservingCollectionIteration(Expr e, boolean includeSynchronized) {
    // Iterates (implicitly) over the elements
    exists(CallableReferencingExpr callableReferencingExpr, string methodName |
        callableReferencingExpr.getQualifier() = e
        and methodName = callableReferencingExpr.getReferencedCallable().(Method).getName()
        and (
            methodName = [
                "iterator",
                "parallelStream",
                "spliterator",
                "stream",
            ]
            or
            includeSynchronized = true and methodName = [
                "forEach",
                "toArray",
            ]
        )
    )
    // Or creates a new Collection which preserves the order of the elements
    or exists(ClassInstanceExpr newCollectionExpr, RefType constructedType |
        constructedType = newCollectionExpr.getConstructedType().getSourceDeclaration()
        and (
            constructedType.getASourceSupertype*() instanceof InsertionOrderSetType
            // Any List or Queue implementation preserves order
            or constructedType.getASourceSupertype*().hasQualifiedName("java.util", ["List", "Queue"])
        )
        and newCollectionExpr.getAnArgument() = e
    )
    // Or used in enhanced `for` statement which implicitly calls `iterator()`
    or exists(EnhancedForStmt forStmt | forStmt.getExpr() = e)
}

/**
 * Holds if the expression represents access to a collection over which a
 * (possibly indirect) iteration is performed.
 */
bindingset[includeSynchronized]
predicate isCollectionIteration(Expr e, boolean includeSynchronized) {
    isOrderPreservingCollectionIteration(e, includeSynchronized)
    // Or creates a new Collection of any type
    or exists(ClassInstanceExpr newCollectionExpr |
        newCollectionExpr.getConstructedType().getSourceDeclaration().getASourceSupertype*() instanceof TypeCollection
        and newCollectionExpr.getAnArgument() = e
    )
}

/**
 * The interface `java.util.Map`.
 */
class TypeMap extends Interface {
    TypeMap() {
        hasQualifiedName("java.util", "Map")
    }
}

/**
 * `Map` subtype which preserves the insertion order.
 */
class InsertionOrderMapType extends RefType {
    InsertionOrderMapType() {
        hasQualifiedName("java.util", "LinkedHashMap")
    }
}

/**
 * `Map` subtype which orders its entries in some consistent way.
 */
class OrderedMapType extends RefType {
    OrderedMapType() {
        this instanceof InsertionOrderMapType
        or hasQualifiedName("java.util", [
            "EnumMap",
            "SortedMap",
        ])
    }
}

/**
 * Holds if the expression represents access to a map over which a
 * (possibly indirect) iteration is performed which preserves the order
 * of the entries.
 * 
 * If `includeSynchronized` is `true` this includes methods which might
 * synchronize on the map.
 */
bindingset[includeSynchronized]
predicate isOrderPreservingMapIteration(Expr e, boolean includeSynchronized) {
    // Iterates (implicitly) over the entries
    exists(CallableReferencingExpr callableReferencingExpr, string methodName |
        callableReferencingExpr.getQualifier() = e
        and methodName = callableReferencingExpr.getReferencedCallable().(Method).getName()
    |
        includeSynchronized = true and methodName = [
            "forEach",
        ]
    )
    // Or creates a new map which preserves the entry insertion order
    or exists(ClassInstanceExpr newMapExpr |
        newMapExpr.getConstructedType().getSourceDeclaration().getASourceSupertype*() instanceof InsertionOrderMapType
        and newMapExpr.getAnArgument() = e
    )
}

/**
 * Holds if the expression represents access to a map over which a
 * (possibly indirect) iteration is performed which preserves the order
 * of the entries.
 */
bindingset[includeSynchronized]
predicate isMapIteration(Expr e, boolean includeSynchronized) {
    isOrderPreservingMapIteration(e, includeSynchronized)
    // Or creates a new map of any type
    or exists(ClassInstanceExpr newMapExpr |
        newMapExpr.getConstructedType().getSourceDeclaration().getASourceSupertype*() instanceof TypeMap
        and newMapExpr.getAnArgument() = e
    )
}

/**
 * Holds if the step from `node1` to `node2` is the access of the key, value or
 * entry collection of a map.
 */
predicate isMapCollectionStep(DataFlow::Node node1, DataFlow::Node node2) {
    exists(MethodAccess call |
        call.getMethod().hasName([
            "entrySet",
            "keySet",
            "values",
        ])
        and node1.asExpr() = call.getQualifier()
        and node2.asExpr() = call
    )
}

/**
 * Holds if the step from `node1` to `node2` is the creation of "sub collections", e.g. a
 * call to `List.subList` or similar.
 */
predicate isSubCollectionStep(DataFlow::Node node1, DataFlow::Node node2) {
    exists(MethodAccess call, Method baseMethod, RefType resultSupertype |
        // Check the return type of the original method to reduce false positives for `List<List<...>>` or similar
        // where element access methods such as `get()` return a collection as well
        baseMethod = call.getMethod().getSourceDeclaration().getASourceOverriddenMethod*()
        and not exists(baseMethod.getASourceOverriddenMethod())
        and resultSupertype = baseMethod.getReturnType().(RefType).getSourceDeclaration().getASourceSupertype*()
        and (
            resultSupertype instanceof TypeCollection
            or resultSupertype instanceof TypeMap
        )
        and node1.asExpr() = call.getQualifier()
        and node2.asExpr() = call
    )
}
