/**
 * @kind path-problem
 */

import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.TaintTracking
import DataFlow::PathGraph

class InsecureUriPiece extends CompileTimeConstantExpr {
  InsecureUriPiece() {
    exists(getStringValue().indexOf([
      "ssl=false",
      "tls=false",
      "tlsInsecure=true",
      "sslInvalidHostNameAllowed=true",
      "tlsAllowInvalidHostnames=true"
    ]))
  }
}

class ConnectionString extends Class {
  ConnectionString() {
    hasQualifiedName("com.mongodb", "ConnectionString")
  }
}

class MongoClientsCreateMethod extends Method {
  MongoClientsCreateMethod() {
    getDeclaringType().hasQualifiedName("com.mongodb.client", "MongoClients")
    and hasStringSignature("create(String)")
  }
}

class LegacyMongoClientUri extends Class {
  LegacyMongoClientUri() {
    hasQualifiedName("com.mongodb", "MongoClientURI")
  }
}

class LegacyMongoClientConstructor extends Constructor {
  LegacyMongoClientConstructor() {
    getDeclaringType().hasQualifiedName("com.mongodb", "MongoClient")
    and getNumberOfParameters() = 1
    and getParameterType(0) instanceof TypeString
  }
}

// TODO: Taint tracking might yield false positives, instead should probably use dataflow
// with custom steps, e.g. String concatenation
class InsecureConnectionStringConfiguration extends TaintTracking::Configuration {
  InsecureConnectionStringConfiguration() { this = "InsecureConnectionStringConfiguration" }

  override predicate isSource(DataFlow::Node source) {
    source.asExpr() instanceof InsecureUriPiece
  }

  override predicate isSink(DataFlow::Node sink) {
    exists(ClassInstanceExpr newExpr |
      newExpr.getAnArgument() = sink.asExpr()
    |
      newExpr.getConstructedType() instanceof ConnectionString
      or newExpr.getConstructedType() instanceof LegacyMongoClientUri
      or exists(Call call |
        call.getCallee() instanceof MongoClientsCreateMethod
        or call.getCallee() instanceof LegacyMongoClientConstructor
      |
        call.getArgument(0) = sink.asExpr()
      )
    )
  }
}

from InsecureConnectionStringConfiguration config, DataFlow::PathNode source, DataFlow::PathNode sink
where config.hasFlowPath(source, sink)
select sink.getNode(), source, sink, "Uses insecure connection string"
