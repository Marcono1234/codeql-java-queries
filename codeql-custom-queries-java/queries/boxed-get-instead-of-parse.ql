/**
 * Finds method calls to the `getX` methods of `Boolean`, `Integer` or `Long`
 * where the argument is not a compile time constant.
 * These `getX` methods parse the System property with the argument name,
 * however the caller might have instead wanted to parse the argument.
 * In this case the `parseX` or `valueOf` method should have been called.
 */

import java

// Only consider methods with one string param, others with
// default value parameter are likely called on purpose
class PropertyParsingMethod extends Method {
    PropertyParsingMethod() {
        (
            getDeclaringType().hasQualifiedName("java.lang", "Boolean")
            and hasStringSignature("getBoolean(String)")
        )
        or (
            getDeclaringType().hasQualifiedName("java.lang", "Integer")
            and hasStringSignature("getInteger(String)")
        )
        or (
            getDeclaringType().hasQualifiedName("java.lang", "Long")
            and hasStringSignature("getLong(String)")
        )
    }
}

from MethodAccess call, PropertyParsingMethod method
where
    method = call.getMethod()
    // Assume that if parsing method is called with compile time constant,
    // then it is called on purpose
    and not exists (call.getAnArgument().(CompileTimeConstantExpr))
select call
