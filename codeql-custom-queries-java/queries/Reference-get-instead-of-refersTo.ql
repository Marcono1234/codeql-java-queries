/**
 * Finds calls to `Reference.get()` which check whether the referenced object
 * has been garbage collected. Such calls can, when performed frequently for
 * some garbage collectors, prevent garbage collection for the referenced
 * object.
 * Instead the method `Reference.refersTo(...)` (added in Java 16) should be
 * used which does not cause these issues. Additionally this method also works
 * for `PhantomReference` for which `get()` would always return `null`.
 *
 * See [JDK-8241029](https://bugs.openjdk.java.net/browse/JDK-8241029) which
 * added the `refersTo` method.
 */

import java

class TypeReference extends Class {
    TypeReference() {
        hasQualifiedName("java.lang.ref", "Reference")
    }
}

class ReferenceGetMethod extends Method {
    ReferenceGetMethod() {
        getDeclaringType().getASourceSupertype*() instanceof TypeReference
        and hasStringSignature("get()")
    }
}

from EqualityTest eqTest
where
    eqTest.getAnOperand().(MethodAccess).getMethod() instanceof ReferenceGetMethod
select eqTest, "Should use Reference.refersTo(...)"
