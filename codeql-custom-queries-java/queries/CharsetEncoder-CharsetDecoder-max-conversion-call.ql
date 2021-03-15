/**
 * Finds calls to `CharsetEncoder.maxBytesPerChar()` and `CharsetDecoder.maxCharsPerByte()`.
 * These methods have two issues:
 * - They return `float`. When calculating the maximum output size for an input (as suggested
 *   by the documentation of these methods), this can lead to precision loss and incorrectly
 *   sized output buffers. The value returned by the methods should therefore first be cast
 *   to `double` before performing any calculations with it.
 * - For `maxBytesPerChar()` the return value also includes the size of output which is
 *   written regardless of the input size, such as BOM. Therefore when calculating the maximum
 *   output size the result could be way larger than the maximum output can actually be.
 *
 * An alternative might be to call `CharsetEncoder.encode(CharBuffer)` or
 * `CharsetDecoder.decode(ByteBuffer)` which perform the complete encoding or decoding
 * operation on their own.
 */

import java

class TypeCharsetEncoder extends Class {
    TypeCharsetEncoder() {
        hasQualifiedName("java.nio.charset", "CharsetEncoder")
    }
}

class TypeCharsetDecoder extends Class {
    TypeCharsetDecoder() {
        hasQualifiedName("java.nio.charset", "CharsetDecoder")
    }
}

private class EncoderDecoderMaxMethod extends Method {
    EncoderDecoderMaxMethod() {
        exists(RefType supertype |
            supertype = getDeclaringType().(RefType).getASourceSupertype*()
        |
            supertype instanceof TypeCharsetEncoder and hasStringSignature("maxBytesPerChar()")
            or supertype instanceof TypeCharsetDecoder and hasStringSignature("maxCharsPerByte()")
        )
    }
}

from MethodAccess maxConversionCall
where
    maxConversionCall.getMethod() instanceof EncoderDecoderMaxMethod
select maxConversionCall, "Calls error-prone max conversion method"
