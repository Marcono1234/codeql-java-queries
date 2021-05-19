/**
 * Finds calls where an array of primitives is passed as single element
 * for a varargs parameter. E.g.:
 * ```java
 * int[] ints = {1, 2, 3};
 * // Creates a List<int[]> instead of the likely desired List<Integer>
 * var list = Arrays.asList(ints);
 * ```
 */

import java

/**
 * - `Method.invoke(Object, Object...)`
 * - `MethodHandle` method
 */
class MethodInvokingMethod extends Method {
    MethodInvokingMethod() {
        (
            getDeclaringType().hasQualifiedName("java.lang.reflect", "Method")
            and hasName("invoke")
        )
        or (
            getDeclaringType().hasQualifiedName("java.lang.invoke", "MethodHandle")
            and hasName(["invoke", "invokeExact", "invokeWithArguments"])
        )
    }
}

private Argument getVarargsArgument(Parameter varargsParam) {
    result.isVararg()
    and result.getCall().getCallee().getAParameter() = varargsParam
}

from Parameter varargsParam, Argument varargsArg
where
    varargsParam.isVarargs()
    and varargsArg = getVarargsArgument(varargsParam)
    and varargsArg.getType().(Array).getComponentType() instanceof PrimitiveType
    // Ignore varargs which have primitive array as component type, e.g. `int[]... ints`
    and not varargsParam.getType().(Array).getComponentType() instanceof Array
    // Ignore if there are multiple varargs arguments, then it is likely on purpose
    and not exists(Argument otherArg |
        otherArg = getVarargsArgument(varargsParam)
        and otherArg.getCall() = varargsArg.getCall()
        and otherArg != varargsArg
    )
    // Ignore `invoke` call; there arguments have to match parameters so it is
    // unlikely that intention was to spread primitive values over method parameters
    and not varargsArg.getCall().getCallee() instanceof MethodInvokingMethod
select varargsArg, "Primitive array is used as single element for $@ varargs parameter", varargsParam, "this"
