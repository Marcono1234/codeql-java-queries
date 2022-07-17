/**
 * Finds calls which use integer literals despite most other calls to the same
 * callable using the value of a constant field. To increase maintainability,
 * the value of the constant field should be preferred. For example:
 * ```java
 * calendar.set(10, 6);
 * // Should be replaced with:
 * calendar.set(Calendar.HOUR, 6);
 * ```
 * 
 * @kind problem
 */

import java

from Call call, IntegerLiteral arg, int argIndex, Callable callee, Field constantField
where
    call.getCallee() = callee
    // Only consider `int` parameters, other types are not commonly used for constants,
    // especially not when instead of a constant a literal is used
    and callee.getParameterType(argIndex).hasName("int")
    and arg = call.getArgument(argIndex)
    and constantField.isStatic()
    and constantField.isFinal()
    // Commonly constant field is defined in same class or supertype
    and constantField.getDeclaringType() = callee.getDeclaringType().getSourceDeclaration().getASourceSupertype*()
    // Decrease false positives and make result message more helpful by trying to look up the exact constant
    // TODO: This also reduces true positives, due to https://github.com/github/codeql/discussions/8650
    and arg.getIntValue() = constantField.getInitializer().(CompileTimeConstantExpr).getIntValue()
    and exists(int constantCallCount, int nonConstantCallCount |
        constantCallCount = count(Call otherCall |
            otherCall.getCallee() = callee
            and otherCall.getArgument(argIndex).(FieldRead).getField() = constantField
        )
        and nonConstantCallCount = count(Call otherCall, Expr otherArg |
            otherCall.getCallee() = callee
            and otherArg = otherCall.getArgument(argIndex)
            and not (
                otherArg instanceof CompileTimeConstantExpr
                // Also cover case where field read is not a compile time constant
                or exists(Field f |
                    f = otherArg.(FieldRead).getField()
                    and f.isStatic()
                    and f.isFinal()
                )
            )
        )
        // Reduce false positives by making sure that multiple calls with constant exist, and
        // that more often constants are used compared to non-constants
        and constantCallCount >= 1
        and (constantCallCount.(float) / nonConstantCallCount) > 2.0
    )
select arg, "Could use constant $@ instead", constantField, constantField.getDeclaringType().getName() + "." + constantField.getName()
