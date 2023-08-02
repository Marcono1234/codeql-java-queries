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
 * @kind problem
 * @precision low
 */

import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.FlowSteps

import lib.Collections
import lib.DataFlowSteps

/**
 * Additional value step which considers flow from assignment to own
 * field to read of own field.
 */
class OwnFieldStep extends AdditionalValueStep {
    override
    predicate step(DataFlow::Node node1, DataFlow::Node node2) {
        isOwnFieldStep(node1, node2)
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
        isOrderPreservingCollectionIteration(sink.asExpr(), true)
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
    predicate isAdditionalFlowStep(DataFlow::Node node1, DataFlow::Node node2) {
        isMapCollectionStep(node1, node2)
    }

    override
    predicate isSink(DataFlow::Node sink) {
        isOrderPreservingMapIteration(sink.asExpr(), true)
        // Or iteration on key, value or entry collection
        or isOrderPreservingCollectionIteration(sink.asExpr(), true)
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
