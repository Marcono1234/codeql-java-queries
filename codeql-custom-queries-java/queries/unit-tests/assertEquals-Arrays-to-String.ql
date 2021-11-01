/**
 * Finds calls to an `assertEquals` method where the arguments are string representations
 * of arrays. Unit test frameworks usually provide specialized assertion methods for arrays,
 * for example JUnit 4 and JUnit 5 provide `assertArrayEquals`. For simplicity these methods
 * should be used instead.
 */

import java
import semmle.code.java.dataflow.DataFlow
import lib.AssertLib

class ArraysToStringCall extends MethodAccess {
    ArraysToStringCall() {
        exists(Method m | m = getMethod() |
            m.getDeclaringType().hasQualifiedName("java.util", "Arrays")
            and m.hasName("toString")
        )
    }
}

from MethodAccess assertEqualsCall, AssertEqualsMethod assertEqualsMethod
where
    assertEqualsCall.getMethod() = assertEqualsMethod
    // All arguments of the assertion use Arrays.toString
    and forex(int paramIndex | paramIndex = assertEqualsMethod.getAnInputParamIndex() |
        DataFlow::localExprFlow(any(ArraysToStringCall c), assertEqualsCall.getArgument(paramIndex))
    )
select assertEqualsCall, "Should use assertion method for arrays instead"
