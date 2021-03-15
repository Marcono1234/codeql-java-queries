/**
 * Finds paths from remote user input to a loop bound. When the loop bound can be
 * controlled by the user, an adversary might be a able to cause a denial of
 * service (DoS) by choosing invalid or large values as bound.
 *
 * @kind path-problem
 */

import java
import DataFlow::PathGraph
import semmle.code.java.dataflow.TaintTracking
import semmle.code.java.dataflow.FlowSources

private predicate isLargeNumberType(Type t) {
    exists(PrimitiveType p |
        p = t or p = t.(BoxedType).getPrimitiveType()
    |
        // float and double are especially problematic in case adversary can
        // use NaN or Infinity
        t.hasName(["int", "long", "float", "double"])
    )
}

class LoopWithBound extends LoopStmt {
    Expr getBound() {
        // for loop assigning value as start value, then counting down
        result = this.(ForStmt).getAnInit()
        // Or comparison with bound
        or exists(ComparisonExpr compExpr |
            compExpr.getParent*() = getCondition()
            and result = compExpr.getAnOperand()
        )
    }
}

class LoopBoundTaintConfiguration extends TaintTracking::Configuration {
    LoopBoundTaintConfiguration() { this = "LoopBoundTaintConfiguration" }
    
    override
    predicate isSource(DataFlow::Node source) {
        source instanceof RemoteFlowSource
    }
    
    override
    predicate isSanitizerOut(DataFlow::Node node) {
        // Conversion to other type (e.g. String) or smaller number type is sanitizer
        not isLargeNumberType(node.getType())
    }
    
    override
    predicate isSink(DataFlow::Node sink) {
        // Only consider large number types, smaller ones might not have DoS effect
        isLargeNumberType(sink.getType())
        and any(LoopWithBound l).getBound() = sink.asExpr()
    }
}

from LoopBoundTaintConfiguration config, DataFlow::PathNode source, DataFlow::PathNode sink
where config.hasFlowPath(source, sink)
select sink.getNode(), source, sink, "Loop bound is based on user input"
