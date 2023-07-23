// Similar to unnecessary-Objects-deepEquals-usage.ql

/**
 * Finds usage of `Object.deepEquals` where `Arrays.deepEquals` could be used instead.
 * Using `Arrays.deepEquals` makes the intention clearer and also provides slightly
 * more type-safety because it requires that its arguments are actually arrays.
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

/**
 * Type `Object[]`
 */
class ObjectArray extends Array {
    ObjectArray() {
        getComponentType() instanceof TypeObject
    }
}

from MethodAccess deepEqualsCall
where
    deepEqualsCall.getMethod() instanceof DeepEqualsMethod
    // Only cover the case where both arguments have type Object[]; other cases such as using String[]
    // are covered by unnecessary-Objects-deepEquals-usage.ql
    and deepEqualsCall.getArgument(0).getType() instanceof ObjectArray
    and deepEqualsCall.getArgument(1).getType() instanceof ObjectArray
select deepEqualsCall, "Could use `Arrays.deepEquals` instead"
