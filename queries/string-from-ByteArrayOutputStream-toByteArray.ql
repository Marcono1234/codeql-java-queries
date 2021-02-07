/**
 * Finds calls of `ByteArrayOutputStream.toByteArray()` which then use
 * the result to create a String. `toByteArray()` returns a copy of the
 * internal byte array, it is therefore more efficient to use one of the
 * `ByteArrayOutputStream.toString(...)` methods because they do not
 * create this redundant copy.
 */

import java

class TypeByteArrayOutputStream extends Class {
    TypeByteArrayOutputStream() {
        hasQualifiedName("java.io", "ByteArrayOutputStream")
    }
}

class ToByteArrayMethod extends Method {
    ToByteArrayMethod() {
        getDeclaringType().getASourceSupertype*() instanceof TypeByteArrayOutputStream
        and hasStringSignature("toByteArray()")
    }
}

from MethodAccess call, ClassInstanceExpr newString
where
    call.getMethod() instanceof ToByteArrayMethod
    and newString.getConstructedType() instanceof TypeString
    and newString.getAnArgument() = call
select call, "Use ByteArrayOutputStream.toString(...) instead"
