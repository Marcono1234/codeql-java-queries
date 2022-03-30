/**
 * Finds flow from remote user input to an argument of a substitution method of Apache Commons Text's
 * `StringSubstitutor`. Depending on how the `StringSubstitutor` was created, it might support
 * potentially dangerous substitution, for example arbitrary script execution.
 * 
 * @kind path-problem
 */

import java
import semmle.code.java.dataflow.TaintTracking
import semmle.code.java.dataflow.FlowSources
import semmle.code.java.dataflow.DataFlow
import DataFlow::PathGraph

class SubstitutorTaintConfig extends TaintTracking::Configuration {
    SubstitutorTaintConfig() { this = "SubstitutorTaintConfig" }

    override predicate isSource(DataFlow::Node source) {
        source instanceof RemoteFlowSource
    }

    override predicate isSink(DataFlow::Node sink) {
        exists(MethodAccess substitutionCall, Method method |
            method = substitutionCall.getMethod()
            and method.getDeclaringType().getASourceSupertype*().hasQualifiedName("org.apache.commons.text", "StringSubstitutor")
            and method.hasName(["replace", "replaceIn"])
            and not method.isStatic()
            and substitutionCall.getArgument(0) = sink.asExpr()
        )
    }
}

from SubstitutorTaintConfig config, DataFlow::PathNode source, DataFlow::PathNode sink
where config.hasFlowPath(source, sink)
select sink, source, sink, "Potentially dangerous string substitution"
