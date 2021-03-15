/**
 * Finds creation of `Random` instances where the seed argument is the
 * current time (e.g. `System.currentTimeMillis()`).
 * There is no need for this because the `Random` constructor with no
 * arguments is, according to the documentation, able to set the seed to:
 * > a value very likely to be distinct from any other invocation of this constructor
 *
 * Manually using the current time as seed can even result in less
 * randomness when multiple `Random` instances are created at the same
 * time.
 */

import java
import semmle.code.java.dataflow.DataFlow

class TimeMethod extends Method {
    TimeMethod() {
        getDeclaringType() instanceof TypeSystem
        and hasStringSignature(["currentTimeMillis()", "nanoTime()"])
    }
}

class TypeRandom extends Class {
    TypeRandom() {
        hasQualifiedName("java.util", "Random")
    }
}

from MethodAccess timeCall, ClassInstanceExpr newRandom
where
    timeCall.getMethod() instanceof TimeMethod
    and newRandom.getConstructedType() instanceof TypeRandom
    and newRandom.getNumArgument() = 1
    and DataFlow::localFlow(DataFlow::exprNode(timeCall), DataFlow::exprNode(newRandom.getArgument(0)))
select newRandom, "Creates Random instance with seed based on time value obtained $@.", timeCall, "here"
