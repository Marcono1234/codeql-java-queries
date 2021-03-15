/**
 * Finds calls of the `valueOf` parsing methods of boxed types where
 * the result is required as primitive type.
 * Since `valueOf` returns a boxed value, this creates unnecessary overhead
 * because the boxed value has to be unboxed again.
 * Instead the `parseX` methods should be used which have primitive return types.
 */

import java
import semmle.code.java.Conversions

class BoxedParsing extends Method {
    BoxedParsing() {
        getDeclaringType() instanceof BoxedType
        // java.lang.Character does not have this parsing method
        and not getDeclaringType().hasQualifiedName("java.lang", "Character")
        and hasStringSignature("valueOf(String)")
    }
}

class PrimitiveGetter extends Method {
    PrimitiveGetter() {
        getNumberOfParameters() = 0
        and exists (string className, string methodName |
            getDeclaringType().hasQualifiedName("java.lang", className)
            and hasName(methodName)
            |
            (className = "Boolean" and methodName = "booleanValue")
            or (className = "Byte" and methodName = "byteValue")
            or (className = "Short" and methodName = "shortValue")
            or (className = "Integer" and methodName = "intValue")
            or (className = "Long" and methodName = "longValue")
            or (className = "Float" and methodName = "floatValue")
            or (className = "Double" and methodName = "doubleValue")
        )
    }
}

from MethodAccess call
where
    call.getMethod() instanceof BoxedParsing
    and (
        // Check if primitive getter method is called on boxed, e.g.: Boolean.valueOf("true").booleanValue()
        exists (MethodAccess boxedCall |
            boxedCall.getQualifier() = call
            and boxedCall.getMethod() instanceof PrimitiveGetter
        )
        or call.(ConversionSite).getConversionTarget() instanceof PrimitiveType
    )
select call
