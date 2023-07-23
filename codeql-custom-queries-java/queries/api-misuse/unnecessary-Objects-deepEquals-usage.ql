/**
 * Finds unnecessary usage of `Objects.deepEquals`. That method is mainly intended for
 * `Object[]` or multi-dimensional arrays. For all other cases this method is not
 * needed and there are other ways to check for equality, which also make the
 * intention clearer:
 * - If both arguments are primitive arrays, use one of the `Arrays.equals` methods,
 *   such as `Arrays.equals(int[], int[])`
 * - If both arguments are one-dimensional arrays with component type other than `Object`,
 *   use `Arrays.equals(Object[], Object[])`
 * - Otherwise use `Objects.equals(Object, Object)` if the arguments can be `null`,
 *   or if not directly call `equals` on one of the arguments
 * 
 * @kind problem
 */

import java

class DeepEqualsMethod extends Method {
    DeepEqualsMethod() {
        getDeclaringType().hasQualifiedName("java.util", "Objects")
        and hasName("deepEquals")
    }
}

from MethodAccess deepEqualsCall, Expr nonObjectArrayArg, Type argType
where
    deepEqualsCall.getMethod() instanceof DeepEqualsMethod
    and nonObjectArrayArg = deepEqualsCall.getAnArgument()
    and argType = nonObjectArrayArg.getType()
    and not (
        argType instanceof TypeObject
        // Object[]
        or argType.(Array).getComponentType() instanceof TypeObject
        // Multi-dimensional array
        or argType.(Array).getComponentType() instanceof Array
    )
select deepEqualsCall, "Unnecessary usage of `Objects.deepEquals` because $@ has neither type `Object` nor `Object[]`, nor is it a multi-dimensional array",
    nonObjectArrayArg, "this argument"
