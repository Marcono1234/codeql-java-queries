/**
 * Finds method calls of `java.util.Base64.Decoder` and `Encoder` where arguments
 * are unnecessarily converted to / from bytes despite there existing separate
 * methods for decoding a String respectively creating a String from the encoded
 * result.
 */

import java

class Base64Decoder extends Class {
    Base64Decoder() {
        getASourceSupertype*().hasQualifiedName("java.util", "Base64$Decoder")
    }
}

class Base64Encoder extends Class {
    Base64Encoder() {
        getASourceSupertype*().hasQualifiedName("java.util", "Base64$Encoder")
    }
}

abstract class ComplicatedBase64Call extends MethodAccess {
    abstract string alternative();
}

class StringGetBytesCall extends MethodAccess {
    StringGetBytesCall() {
        exists (Method m | m = getMethod() |
            m.getDeclaringType() instanceof TypeString
            and m.hasName("getBytes")
        )
    }
}

class ComplicatedBase64DecoderCall extends ComplicatedBase64Call {
    ComplicatedBase64DecoderCall() {
        exists (Method m | m = getMethod() |
            m.getDeclaringType() instanceof Base64Decoder
            and m.hasStringSignature("decode(byte[])")
        )
        // Obtains byte[] argument from String
        and getArgument(0) instanceof StringGetBytesCall
    }
    
    override
    string alternative() {
        result = "decode(String)"
    }
}

class ComplicatedBase64EncoderCall extends ComplicatedBase64Call {
    ComplicatedBase64EncoderCall() {
        exists (Method m | m = getMethod() |
            m.getDeclaringType() instanceof Base64Encoder
            and m.hasStringSignature("encode(byte[])")
        )
        // Creates String from byte[] result
        and getParent().(ClassInstanceExpr).getConstructedType() instanceof TypeString
    }
    
    override
    string alternative() {
        result = "encodeToString(byte[])"
    }
}

from ComplicatedBase64Call complicatedCall
select complicatedCall, "Should use " + complicatedCall.alternative()
