/**
 * Finds constructor calls of `java.lang.ref.PhantomReference` where the `ReferenceQueue`
 * argument is `null`. As described by the documentation of the constructor, `null` is
 * allowed as value but does not make any sense because `PhantomReference`'s only
 * purpose is to detect when the referenced object has been garbage collected by checking
 * the ReferenceQueue; the `PhantomReference.get()` method always returns `null`.
 */

import java
import semmle.code.java.dataflow.DataFlow

class PhantomReferenceType extends Class {
    PhantomReferenceType() {
        hasQualifiedName("java.lang.ref", "PhantomReference")
    }
}

// TODO: This can probably be simplified; data flow might not be necessary (also causes false positives?)
class NullRefQueueConfiguration extends DataFlow::Configuration {
    NullRefQueueConfiguration() { this = "NullRefQueueConfiguration" }

    override predicate isSource(DataFlow::Node source) {
        source.asExpr() instanceof NullLiteral
    }

    override predicate isSink(DataFlow::Node sink) {
        exists (ConstructorCall constructorCall |
            constructorCall.getConstructedType() instanceof PhantomReferenceType
            and constructorCall.getArgument(1) = sink.asExpr()
        )
    }
}

from NullRefQueueConfiguration config, DataFlow::Node source, DataFlow::Node sink
where config.hasFlow(source, sink)
select sink, "Creates PhantomReference with null as ReferenceQueue from $@.", source, "here"
