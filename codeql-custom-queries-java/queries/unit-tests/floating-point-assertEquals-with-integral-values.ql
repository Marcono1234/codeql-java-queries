/**
 * Finds usage of `assertEquals` and `assertNotEquals` methods with floating point delta
 * parameter which are used for integral number arguments.
 * For example `assertEquals(double, double, double)`:
 * ```java
 * assertEquals(expectedCount, obj.getCount(), 0);
 * ```
 * When the compared arguments are integral numbers the regular `assertEquals` methods should
 * be used, such as `assertEquals(int, int)`.
 * 
 * @kind problem
 */

import java

// TODO: Maybe use classes from AssertLib.qll?
from MethodAccess assertCall, Method assertMethod, int argStartIndex, CompileTimeConstantExpr deltaArg
where
    assertMethod = assertCall.getMethod()
    and assertMethod.hasName(["assertEquals", "assertNotEquals"])
    // Use argStartIndex variable to skip over message parameter, in case there is one
    and assertMethod.getParameterType(argStartIndex) instanceof FloatingPointType
    and assertMethod.getParameterType(argStartIndex + 1) instanceof FloatingPointType
    and assertMethod.getParameterType(argStartIndex + 2) instanceof FloatingPointType
    and assertCall.getArgument(argStartIndex).getType() instanceof IntegralType
    and assertCall.getArgument(argStartIndex + 1).getType() instanceof IntegralType
    // Check delta argument to reduce false positives for intentional usage of this assertion method
    and deltaArg = assertCall.getArgument(argStartIndex + 2)
    and (
        deltaArg.getIntValue() = 0
        or deltaArg.(LongLiteral).getValue() = "0"
        or deltaArg.(FloatLiteral).getFloatValue() < 1
        or deltaArg.(DoubleLiteral).getDoubleValue() < 1
    )
select assertCall, "Should not use floating point assertion method for integral arguments"
