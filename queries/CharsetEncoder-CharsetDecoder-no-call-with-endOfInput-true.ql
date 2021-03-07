/**
 * Finds classes which use `CharsetEncoder` or `CharsetDecoder` to perform
 * an encoding respectively decoding operation and always use `false` as
 * `endOfInput` argument. When the coding operation has reached the end of
 * input the coding method must be called with `true` as `endOfInput`,
 * otherwise incomplete input will not be detected by the encoder / decoder.
 */

import java

class EndOfInputCodingOperationMethod extends Method {
    EndOfInputCodingOperationMethod() {
        getDeclaringType().getASourceSupertype*().hasQualifiedName("java.nio.charset", ["CharsetEncoder", "CharsetDecoder"])
        and hasStringSignature([
          "encode(CharBuffer, ByteBuffer, boolean)",
          "decode(ByteBuffer, CharBuffer, boolean)"
        ])
    }
    
    int getEndOfInputParamIndex() {
        result = 2
    }
}

private string getSimpleMethodName(Method m) {
    result = m.getDeclaringType().getName() + "." + m.getName()
}

from Class c, MethodAccess codingCall, EndOfInputCodingOperationMethod codingMethod
where
    // Only consider if part of source code
    c.fromSource()
    and codingCall.getMethod() = codingMethod
    // Always calls with `endOfInput=false`
    and codingCall.getArgument(codingMethod.getEndOfInputParamIndex()).(CompileTimeConstantExpr).getBooleanValue() = false
    and codingCall.getEnclosingCallable().getDeclaringType() = c
    // And there is no call with `endOfInput=true`
    and not exists(MethodAccess otherCodingCall, Argument endOfInputArg |
        otherCodingCall.getMethod() = codingMethod
        and otherCodingCall.getEnclosingCallable().getDeclaringType() = c
        and endOfInputArg = otherCodingCall.getArgument(codingMethod.getEndOfInputParamIndex())
        and (
            // Called with `true`
            endOfInputArg.(CompileTimeConstantExpr).getBooleanValue() = true
            // Or not a constant value, in which case the value might be `true`
            or not endOfInputArg instanceof CompileTimeConstantExpr
        )
    )
select c, "Calls " + getSimpleMethodName(codingMethod) + " $@ with endOfInput=false, but never calls method with endOfInput=true",
    codingCall, "here"
