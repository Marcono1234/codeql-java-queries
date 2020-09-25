/**
 * Finds expressions which calculate the elapsed time using `System.currentTimeMillis()`.
 * This method returns the time as reported by the OS. This can be problematic because
 * often a background task is running which keeps the OS time in sync with the world
 * time. It could therefore happen that during time measurement the OS adjusts the system
 * time and the calculated elapsed time becomes incorrect; it could even become negative.
 *
 * It is recommended to use `System.nanoTime()` instead for elapsed time measurement.
 */

import java
import semmle.code.java.dataflow.DataFlow

class CurrentTimeMillisMethod extends Method {
    CurrentTimeMillisMethod() {
        getDeclaringType() instanceof TypeSystem
        and hasStringSignature("currentTimeMillis()")
    }
}

class CurrentTimeSubtractionConfig extends DataFlow::Configuration {
    CurrentTimeSubtractionConfig() { this = "CurrentTimeSubtractionConfig" }

    override predicate isSource(DataFlow::Node source) {
        source.asExpr().(MethodAccess).getMethod() instanceof CurrentTimeMillisMethod
    }

    override predicate isSink(DataFlow::Node sink) {
        exists (SubExpr subExpr |
            subExpr.getAnOperand() = sink.asExpr()
        )
    }
}

// Verify that both operands of subtraction have System.currentTimeMillis() value, otherwise
// might be expression which just offsets current time
from CurrentTimeSubtractionConfig dataflow, DataFlow::Node source1, DataFlow::Node sink1, SubExpr subExpr, DataFlow::Node source2, DataFlow::Node sink2
where
    subExpr.getLeftOperand() = sink1.asExpr()
    and subExpr.getRightOperand() = sink2.asExpr()
    and dataflow.hasFlow(source1, sink1)
    and dataflow.hasFlow(source2, sink2)
select subExpr, "Calculates elapsed time using System.currentTimeMillis() values from $@ and $@.", source1, "here", source2, "here"
