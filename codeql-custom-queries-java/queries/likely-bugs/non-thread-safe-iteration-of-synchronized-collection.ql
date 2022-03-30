/**
 * Finds non-thread-safe iteration of synchronized collections created by one of the
 * `Collections.synchronized...` methods. As described by the documentation of these
 * methods, most iteration methods (such as using `iterator()`) are not thread-safe
 * and require synchronizing on the collection instance.
 */

import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.FlowSteps

import lib.Collections
import lib.DataFlowSteps

class SynchronizedCollectionMethodCall extends MethodAccess {
    SynchronizedCollectionMethodCall() {
        exists(Method m | m = getMethod() |
            m.getDeclaringType().hasQualifiedName("java.util", "Collections")
            and m.getName().matches("synchronized%")
        )
    }
}

class UnsafeIterationFlowConfig extends DataFlow::Configuration {
    UnsafeIterationFlowConfig() { this = "UnsafeIterationFlowConfig" }

    override
    predicate isSource(DataFlow::Node source) {
        source.asExpr() instanceof SynchronizedCollectionMethodCall
    }

    override
    predicate isAdditionalFlowStep(DataFlow::Node node1, DataFlow::Node node2) {
        isOwnFieldStep(node1, node2)
        or isMapCollectionStep(node1, node2)
        or isSubCollectionStep(node1, node2)
    }

    override
    predicate isSink(DataFlow::Node sink) {
        isCollectionIteration(sink.asExpr(), false)
        or isMapIteration(sink.asExpr(), false)
    }
}

class DataFlowWithFieldStep extends DataFlow::Configuration {
    DataFlowWithFieldStep() { this = "DataFlowWithFieldStep" }

    override
    predicate isSource(DataFlow::Node source) {
        // Is restricted when config predicates are used
        any()
    }

    override
    predicate isAdditionalFlowStep(DataFlow::Node node1, DataFlow::Node node2) {
        isOwnFieldStep(node1, node2)
    }

    override
    predicate isSink(DataFlow::Node sink) {
        // Is restricted when config predicates are used
        any()
    }
}

from UnsafeIterationFlowConfig config, DataFlow::Node source, DataFlow::Node sink
where
    config.hasFlow(source, sink)
    and (
        // Method reference cannot be protected with `synchronized` statement
        sink.asExpr() instanceof MemberRefExpr
        // Or not protected with `synchronized` statement
        or not exists(DataFlowWithFieldStep synchronizedConfig, SynchronizedStmt synchronizedStmt |
            synchronizedConfig.hasFlow(source, any(DataFlow::Node node | node.asExpr() = synchronizedStmt.getExpr()))
            and synchronizedStmt.getBlock() = sink.asExpr().getAnEnclosingStmt()
        )
    )
select sink, "Performs non-thread-safe iteration on synchronized collection created $@", source, "here"
