/**
 * Finds expressions which use the result of `java.lang.ref.Reference.get()`
 * (or an override) without checking if the returned value is `null`.
 */

import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.Nullness
import semmle.code.java.dataflow.NullGuards

class ReferenceType extends Class {
    ReferenceType() {
        hasQualifiedName("java.lang.ref", "Reference")
    }
}

class ReferenceGetMethod extends Method {
    ReferenceGetMethod() {
        getDeclaringType().getASourceSupertype*() instanceof ReferenceType
        and hasStringSignature("get()")
    }
}

class ReferenceGetDerefConfig extends DataFlow::Configuration {
    ReferenceGetDerefConfig() {
        this = "ReferenceGetDerefConfig"
    }
    
    override predicate isSource(DataFlow::Node source) {
        source.asExpr().(MethodAccess).getMethod() instanceof ReferenceGetMethod
    }
    
    override predicate isSink(DataFlow::Node sink) {
        // TODO: This erroneously finds usage of `this` (which is never null) instead of method which is called on that object
        dereference(sink.asExpr())
    }
    
    override predicate isBarrier(DataFlow::Node node) {
        // TODO: Might be incorrect usage
        exists (basicNullGuard(node.asExpr(), _, _))
    }
}

from ReferenceGetDerefConfig config, DataFlow::Node src, DataFlow::Node sink
where config.hasFlow(src, sink)
select sink, "Dereferences potential null value from Reference.get() obtained $@.", src, "here"
