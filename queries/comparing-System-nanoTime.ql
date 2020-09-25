/**
 * Finds comparison expressions where at least one of the operands has the value
 * of `System.nanoTime()`. As described in the documentation the return value of
 * this method is not related to wall-clock time, it might even be negative. Therefore
 * using a comparison expression can result in incorrect behavior when the value
 * overflows between the two points in time when the values are retrieved.
 * Instead the difference between the two values should be calculated and then
 * that result should be compared.
 *
 * See https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/lang/System.html#nanoTime()
 */

import java
import semmle.code.java.dataflow.DataFlow

class NanoTimeMethod extends Method {
    NanoTimeMethod() {
        getDeclaringType() instanceof TypeSystem
        and hasStringSignature("nanoTime()")
    }
}

class NanoTimeComparisonConfig extends DataFlow::Configuration {
    NanoTimeComparisonConfig() { this = "NanoTimeComparisonConfig" }

    override predicate isSource(DataFlow::Node source) {
        source.asExpr().(MethodAccess).getMethod() instanceof NanoTimeMethod
    }

    override predicate isSink(DataFlow::Node sink) {
        exists (ComparisonExpr comparisonExpr |
            comparisonExpr.getAnOperand() = sink.asExpr()
        )
    }
}

from NanoTimeComparisonConfig dataflow, DataFlow::Node source, DataFlow::Node sink
where dataflow.hasFlow(source, sink)
select sink, "Compares System.nanoTime() value retrieved $@.", source, "here"
