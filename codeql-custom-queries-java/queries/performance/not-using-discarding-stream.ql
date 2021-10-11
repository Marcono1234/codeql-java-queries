/**
 * Finds usage of `ByteArrayOutputStream` and `StringWriter` which appears to be intended
 * as discarding any written data. This is rather inefficient because these classes
 * still store all data, even if it is not accessed afterwards anymore.
 * 
 * Instead `OutputStream.nullOutputStream()` and `Writer.nullWriter()` (added in Java 11)
 * or similar stream classes provided by a library should be used because they are more efficient.
 */

import java

abstract class StreamClassWithAlternative extends RefType {
    abstract string getAlternative();
}

class TypeByteArrayOutputStream extends StreamClassWithAlternative {
    TypeByteArrayOutputStream() {
        hasQualifiedName("java.io", "ByteArrayOutputStream")
    }

    override
    string getAlternative() {
        result = "OutputStream.nullOutputStream()"
    }
}

class TypeStringWriter extends StreamClassWithAlternative {
    TypeStringWriter() {
        hasQualifiedName("java.io", "StringWriter")
    }

    override
    string getAlternative() {
        result = "Writer.nullWriter()"
    }
}

// Detects cases where `new ...` is passed directly as argument, and therefore
// its data cannot be retrieved by the caller
from Call call, int argIndex, ClassInstanceExpr newStreamExpr, StreamClassWithAlternative streamClass
where
    call.getArgument(argIndex) = newStreamExpr
    and newStreamExpr.getConstructedType() = streamClass
    // And parameter type is not explicitly `streamClass` (then callee might retrieve
    // its content)
    and call.getCallee().getParameterType(argIndex) != streamClass
select newStreamExpr, "Should use " + streamClass.getAlternative() + " instead"
