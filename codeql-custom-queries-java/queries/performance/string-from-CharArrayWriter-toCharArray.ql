/**
 * Finds calls of `CharArrayWriter.toCharArray()` which then use
 * the result to create a String. `toCharArray()` returns a copy of the
 * internal char array, it is therefore more efficient to use the method
 * `CharArrayWriter.toString()` because it does not create this redundant
 * copy.
 */

import java

class TypeCharArrayWriter extends Class {
    TypeCharArrayWriter() {
        hasQualifiedName("java.io", "CharArrayWriter")
    }
}

class ToCharArrayMethod extends Method {
    ToCharArrayMethod() {
        getDeclaringType().getASourceSupertype*() instanceof TypeCharArrayWriter
        and hasStringSignature("toCharArray()")
    }
}

from MethodAccess call, ClassInstanceExpr newString
where
    call.getMethod() instanceof ToCharArrayMethod
    and newString.getConstructedType() instanceof TypeString
    and newString.getAnArgument() = call
    // Only consider if char array is sole argument; ignore if only section
    // of char array is used for string creation, e.g. `new String(..., 0, 10)`
    and newString.getNumArgument() = 1
select call, "Use CharArrayWriter.toString() instead"
