/**
 * Finds creation of `Set` or `Map` instances which do not have a deterministic iteration
 * order, such as `HashSet`, but over whose elements respectively entries the code later
 * iterates. Because the iteration order is non-deterministic, this can make the behavior
 * of the complete application non-deterministic. When a deterministic iteration order is
 * desired, the classes `LinkedHashSet` and `LinkedHashMap` can be used instead.
 *
 * Note that the precision of this query is rather low, in many cases the iteration order
 * is irrelevant.
 *
 * @precision low
 */

import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.FlowSteps

predicate isOwnFieldAccess(FieldAccess fieldAccess) {
    fieldAccess.getField().isStatic()
    or fieldAccess.isOwnFieldAccess()
}

/**
 * Additional value step which considers flow from assignment to own
 * field to read of own field.
 */
class OwnFieldStep extends AdditionalValueStep {
    override
    predicate step(DataFlow::Node node1, DataFlow::Node node2) {
        exists(FieldWrite fieldWrite, FieldRead fieldRead |
            fieldWrite.getField() = fieldRead.getField()
            and isOwnFieldAccess(fieldWrite)
            and isOwnFieldAccess(fieldRead)
            and fieldWrite.getRHS() = node1.asExpr()
            and fieldRead = node2.asExpr()
        )
    }
}

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

class SetFlowConfig extends DataFlow::Configuration {
    SetFlowConfig() { this = "SetFlowConfig" }

    override
    predicate isSource(DataFlow::Node source) {
        // Creates a new set of a type which does not have a consistent order
        exists(ClassInstanceExpr newSetExpr, RefType constructedType |
            newSetExpr = source.asExpr()
            and constructedType = newSetExpr.getConstructedType().getSourceDeclaration()
            and constructedType.getASourceSupertype*() instanceof TypeSet
            and not constructedType.getASourceSupertype*() instanceof OrderedSetType
        )
        // Or creates an unmodifiable set; documentation says unmodifiable sets have no defined iteration order
        or exists(MethodAccess factoryMethodCall, Method factoryMethod |
            factoryMethodCall = source.asExpr()
            and factoryMethod = factoryMethodCall.getMethod()
            and factoryMethod.getSourceDeclaration().getDeclaringType() instanceof TypeSet
            and factoryMethod.hasName(["copyOf", "of"])
        )
    }

    override
    predicate isSink(DataFlow::Node sink) {
        // Iterates (implicitly) over the elements
        exists(MethodAccess methodCall |
            methodCall.getQualifier() = sink.asExpr()
            and methodCall.getMethod().hasName([
                "forEach",
                "iterator",
                "parallelStream",
                "spliterator",
                "stream",
                "toArray",
            ])
        )
        // Or creates a new Collection which preserves the order of the elements
        or exists(ClassInstanceExpr newCollectionExpr, RefType constructedType |
            constructedType = newCollectionExpr.getConstructedType().getSourceDeclaration()
            and (
                constructedType.getASourceSupertype*() instanceof InsertionOrderSetType
                // Any List or Queue implementation preserves order
                or constructedType.getASourceSupertype*().hasQualifiedName("java.util", ["List", "Queue"])
            )
            and newCollectionExpr.getAnArgument() = sink.asExpr()
        )
    }
}

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

class MapFlowConfig extends DataFlow::Configuration {
    MapFlowConfig() { this = "MapFlowConfig" }

    override
    predicate isSource(DataFlow::Node source) {
        // Creates a new map of a type which does not have a consistent order
        exists(ClassInstanceExpr newMapExpr, RefType constructedType |
            newMapExpr = source.asExpr()
            and constructedType = newMapExpr.getConstructedType().getSourceDeclaration()
            and constructedType.getASourceSupertype*() instanceof TypeMap
            and not constructedType.getASourceSupertype*() instanceof OrderedMapType
        )
        // Or creates an unmodifiable map; documentation says unmodifiable maps have no defined iteration order
        or exists(MethodAccess factoryMethodCall, Method factoryMethod |
            factoryMethodCall = source.asExpr()
            and factoryMethod = factoryMethodCall.getMethod()
            and factoryMethod.getSourceDeclaration().getDeclaringType() instanceof TypeMap
            and factoryMethod.hasName(["copyOf", "of", "ofEntries"])
        )
    }

    override
    predicate isSink(DataFlow::Node sink) {
        // Iterates (implicitly) over the entries
        exists(MethodAccess methodCall |
            methodCall.getQualifier() = sink.asExpr()
            and methodCall.getMethod().hasName([
                "entrySet",
                "forEach",
                "keySet",
                "values",
            ])
        )
        // Or creates a new map which preserves the entry insertion order
        or exists(ClassInstanceExpr newCollectionExpr |
            newCollectionExpr.getConstructedType().getSourceDeclaration().getASourceSupertype*() instanceof InsertionOrderMapType
            and newCollectionExpr.getAnArgument() = sink.asExpr()
        )
    }
}

from DataFlow::Configuration config, DataFlow::Node source, DataFlow::Node sink, string collectionType
where
    (
        config instanceof SetFlowConfig
        and collectionType = "Set"
        or
        config instanceof MapFlowConfig
        and collectionType = "Map"
    )
    and config.hasFlow(source, sink)
select source, "Creates a " + collectionType + " which does not have a consistent iteration order, and iterates over its elements $@.", sink, "here"
