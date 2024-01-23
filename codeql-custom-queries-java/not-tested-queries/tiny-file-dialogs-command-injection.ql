/**
 * Using untrusted input with the Tiny File Dialogs library can lead to command
 * injection vulnerabilities.
 *
 * See also [this LWJGL GitHub issue](https://github.com/LWJGL/lwjgl3/issues/951).
 *
 * @kind path-problem
 */

// TODO: Not tested yet

import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.FlowSources

// For 3.3.4-SNAPSHOT; https://javadoc.lwjgl.org/org/lwjgl/util/tinyfd/TinyFileDialogs.html
class TinyFdSink extends DataFlow::Node {
  TinyFdSink() {
    exists(MethodAccess call, Method m |
      m = call.getMethod() and
      m.getDeclaringType().hasQualifiedName("org.lwjgl.util.tinyfd", "TinyFileDialogs") and
      this.asExpr() = call.getAnArgument() and
      // Match text provided as `long` address, `ByteBuffer` and `CharSequence`
      // Note: Flow for `long` as memory address is probably not well supported by taint tracking yet
      // TODO: Maybe make this more specific in case this leads to false positives
      (this.getType().hasName("long") or not this.getType() instanceof PrimitiveType)
    )
  }
}

module TinyFdFlowConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node source) { source instanceof RemoteFlowSource }

  predicate isSink(DataFlow::Node sink) { sink instanceof TinyFdSink }
}

module TinyFdFlow = TaintTracking::Global<TinyFdFlowConfig>;

import TinyFdFlow::PathGraph

from TinyFdFlow::PathNode source, TinyFdFlow::PathNode sink
where TinyFdFlow::flowPath(source, sink)
select sink.getNode(), source, sink, "Untrusted input used as argument for Tiny File Dialogs"
