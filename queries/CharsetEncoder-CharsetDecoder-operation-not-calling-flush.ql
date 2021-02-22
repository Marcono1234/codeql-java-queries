/**
 * Finds classes which use `CharsetEncoder` or `CharsetDecoder` to perform
 * an encoding respectively decoding operation, but which are not calling
 * `flush(...)`. A complete encoding or decoding operation consists of
 * calling `encode(...)` / `decode(...)` and eventually `flush(...)` at
 * the end of input. Not doing so leaves the output in an incomplete state
 * for certain encodings.
 */

import java

class TypeCharsetEncoder extends Class {
    TypeCharsetEncoder() {
        hasQualifiedName("java.nio.charset", "CharsetEncoder")
    }
}

class CharsetEncoderEncodeMethod extends Method {
    CharsetEncoderEncodeMethod() {
        getDeclaringType().(RefType).getASourceSupertype*() instanceof TypeCharsetEncoder
        and hasStringSignature("encode(CharBuffer, ByteBuffer, boolean)")
    }
}

class CharsetEncoderFlushMethod extends Method {
    CharsetEncoderFlushMethod() {
        getDeclaringType().(RefType).getASourceSupertype*() instanceof TypeCharsetEncoder
        and hasName("flush")
    }
}

class TypeCharsetDecoder extends Class {
    TypeCharsetDecoder() {
        hasQualifiedName("java.nio.charset", "CharsetDecoder")
    }
}

class CharsetDecoderDecodeMethod extends Method {
    CharsetDecoderDecodeMethod() {
        getDeclaringType().(RefType).getASourceSupertype*() instanceof TypeCharsetDecoder
        and hasStringSignature("decode(ByteBuffer, CharBuffer, boolean)")
    }
}

class CharsetDecoderFlushMethod extends Method {
    CharsetDecoderFlushMethod() {
        getDeclaringType().(RefType).getASourceSupertype*() instanceof TypeCharsetDecoder
        and hasName("flush")
    }
}

private string getSimpleMethodSignature(Method m) {
    result = m.getDeclaringType().getName() + "." + m.getStringSignature()
}

from Class c, Method encodeDecodeMethod, MethodAccess encodeDecodeCall, Method flushMethod
where
    // Only consider if part of source code
    c.fromSource()
    and encodeDecodeCall.getMethod() = encodeDecodeMethod
    and encodeDecodeCall.getEnclosingCallable().getDeclaringType() = c
    and not exists(MethodAccess flushCall |
        flushCall.getMethod() = flushMethod
        and flushCall.getEnclosingCallable().getDeclaringType() = c
    )
    and (
        (
            encodeDecodeMethod instanceof CharsetEncoderEncodeMethod
            and flushMethod instanceof CharsetEncoderFlushMethod
        )
        or (
            encodeDecodeMethod instanceof CharsetDecoderDecodeMethod
            and flushMethod instanceof CharsetDecoderFlushMethod
        )
    )
select c, "Calls " + getSimpleMethodSignature(encodeDecodeMethod) + " $@ but does not call flush(...)", encodeDecodeCall, "here"
