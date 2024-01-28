/**
 * Detects flow from remote user input to a lookup of an environment variable or
 * a System property. Some environment variables or System properties might store
 * sensitive data, therefore letting an untrusted user access them should be avoided.
 *
 * @id todo
 * @kind path-problem
 */

// TODO: The flow reported by this query is not very useful yet; might have to
// define more barriers, or switch from taint to data flow? (but that might cause
// too many false negatives)

import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.FlowSources

/**
 * If a method is called which allows retrieving the value for an entry
 * in some form, has the expression which is used as key as result.
 */
Expr getKeyArg(MethodAccess mapMethodCall) {
  exists(Method m |
    m = mapMethodCall.getMethod().getSourceDeclaration() and
    (
      // Also considers 'setter' methods since they return the value
      m.hasName([
          "compute", "computeIfAbsent", "computeIfPresent", "get", "getOrDefault", "merge", "put",
          "putIfAbsent", "replace",
          // `java.util.Properties` methods
          "getProperty", "setProperty"
        ])
      or
      // `remove(key)`; ignore `remove(key, value)` which returns `boolean`
      m.hasName("remove") and m.getNumberOfParameters() = 1
    ) and
    // Key arg is for all these methods at index 0
    result = mapMethodCall.getArgument(0)
  )
}

/** Sink for environment variable name */
class EnvSink extends DataFlow::Node {
  EnvSink() {
    exists(MethodAccess getEnvCall, Method getEnvMethod |
      getEnvCall.getMethod() = getEnvMethod and
      getEnvMethod.getDeclaringType() instanceof TypeSystem and
      getEnvMethod.hasName("getenv")
    |
      // Call to `System.getenv(arg)`
      this.asExpr() = getEnvCall.getArgument(0)
      or
      // Call to `System.getenv()` followed by map value lookup
      getEnvMethod.hasNoParameters() and
      exists(MethodAccess mapMethodCall |
        DataFlow::localExprFlow(getEnvCall, mapMethodCall.getQualifier()) and
        this.asExpr() = getKeyArg(mapMethodCall)
      )
    )
  }
}

/** Sink for System property name */
class SystemPropertySink extends DataFlow::Node {
  SystemPropertySink() {
    // Call to `System.getProperty(arg)`
    exists(MethodAccess getPropertyCall, Method getPropertyMethod |
      getPropertyCall.getMethod() = getPropertyMethod and
      getPropertyMethod.getDeclaringType() instanceof TypeSystem and
      getPropertyMethod.hasName("getProperty")
    |
      this.asExpr() = getPropertyCall.getArgument(0)
    )
    or
    // Call to `System.getProperties()` followed by property lookup
    exists(
      MethodAccess getPropertiesCall, Method getPropertiesMethod, MethodAccess propertiesMethodCall
    |
      getPropertiesCall.getMethod() = getPropertiesMethod and
      getPropertiesMethod.getDeclaringType() instanceof TypeSystem and
      getPropertiesMethod.hasName("getProperties")
    |
      DataFlow::localExprFlow(getPropertiesCall, propertiesMethodCall.getQualifier()) and
      this.asExpr() = getKeyArg(propertiesMethodCall)
    )
  }
}

module EnvLookupConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node source) { source instanceof RemoteFlowSource }

  predicate isSink(DataFlow::Node sink) {
    sink instanceof EnvSink or sink instanceof SystemPropertySink
  }

  predicate isBarrier(DataFlow::Node node) {
    // Try to reduce false positives by ignoring method calls where the real receiver type
    // is unknown
    exists(MethodAccess call | call = node.asExpr() |
      call.getReceiverType() instanceof TypeObject and
      call.getMethod() instanceof ToStringMethod
      or
      call.getMethod().isAbstract()
    )
  }
}

module EnvLookupFlow = TaintTracking::Global<EnvLookupConfig>;

import EnvLookupFlow::PathGraph

from EnvLookupFlow::PathNode source, EnvLookupFlow::PathNode sink
where EnvLookupFlow::flowPath(source, sink)
select sink.getNode(), source, sink,
  "Remote user input flows into lookup of environment variable or System property"
