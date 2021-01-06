/**
 * Finds calls to `Class.isInstance(Object)` with a type literal
 * as qualifier, e.g.:
 * ```
 * String.class.isInstance(obj)
 * ```
 * The `instanceof` expression should be used instead, e.g.:
 * ```
 * obj instanceof String
 * ```
 */

import java

class IsInstanceMethod extends Method {
    IsInstanceMethod() {
        getDeclaringType() instanceof TypeClass
        and hasStringSignature("isInstance(Object)")
    }
}

from MethodAccess isInstanceCall
where
    exists (IsInstanceMethod m | isInstanceCall.getMethod().getSourceDeclaration().overridesOrInstantiates*(m))
    and isInstanceCall.getQualifier() instanceof TypeLiteral
select isInstanceCall, "Usage of Class.isInstance(...) with type literal as qualifier."
