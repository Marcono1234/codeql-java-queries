/**
 * Finds data flow from a user-controlled value to the creation of a `Throwable`.
 * By default methods such as `printStackTrace()` do not perform any special escaping
 * of the exception message so it is therefore for example possible to forge stack
 * trace frames by using line terminators in the user-controlled value.
 *
 * @kind path-problem
 */

import java
import semmle.code.java.dataflow.FlowSources
import DataFlow::PathGraph

class ExceptionMessageInjectionConfiguration extends TaintTracking::Configuration {
    ExceptionMessageInjectionConfiguration() {
        this = "ExceptionMessageInjection"
    }
    
    override predicate isSource(DataFlow::Node source) {
        source instanceof RemoteFlowSource
    }

    override predicate isSink(DataFlow::Node sink) {
        exists (ClassInstanceExpr newExpr |
            newExpr.getConstructedType().getAnAncestor() instanceof TypeThrowable
            and newExpr.getAnArgument() = sink.asExpr()
        )
    }
}

from ExceptionMessageInjectionConfiguration config, DataFlow::PathNode source, DataFlow::PathNode sink
where
    config.hasFlowPath(source, sink)
select sink.getNode(), source, sink, "Exception message is created using user-controlled $@.", source.getNode(), "data"
