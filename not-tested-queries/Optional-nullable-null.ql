/**
 * Finds method calls which create an `Optional` from a `null` literal, e.g.:
 * ```
 * Optional<String> s = Optional.ofNullable(null);
 * ```
 *
 * Instead the respective method for obtaining an empty `Optional` should be
 * used. For `java.util.Optional` that is `Optional.empty()`.
 */

import java

abstract class NullableOptionalMethod extends Method {
    abstract string emptyOptionalMethod();
}

class GuavaNullableOptionalMethod extends NullableOptionalMethod {
    GuavaNullableOptionalMethod() {
        getDeclaringType().hasQualifiedName("com.google.common.base", "Optional")
        and hasName("fromNullable")
    }
    
    override
    string emptyOptionalMethod() {
        result = "Optional.absent()"
    }
}

class JdkNullableOptionalMethod extends NullableOptionalMethod {
    JdkNullableOptionalMethod() {
        getDeclaringType().hasQualifiedName("java.util", "Optional")
        and hasName("ofNullable")
    }
    
    override
    string emptyOptionalMethod() {
        result = "Optional.empty()"
    }
}

from NullableOptionalMethod optionalMethod, MethodAccess call
where
    call.getMethod() = optionalMethod
    and call.getArgument(0) instanceof NullLiteral
select call, "Should use " + optionalMethod.emptyOptionalMethod()
