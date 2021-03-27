/**
 * Finds calls to one of the `Integer` `toString` methods with a `byte`
 * value as argument. `byte` is signed, so directly providing it as
 * argument will yield unexpected results for negative byte values.
 * Instead the byte should be converted to an unsigned `int` by using
 * `b & 0xFF` as argument.
 * 
 * Alternatively `java.util.HexFormat` added in Java 17 or similar
 * classes from third-party libraries could be used.
 */

import java

class IntegerToStringCall extends MethodAccess {
    IntegerToStringCall() {
        exists (Method m | m = getMethod() |
            m.getDeclaringType().hasQualifiedName("java.lang", "Integer")
            and (
                m.hasName(["toBinaryString", "toOctalString", "toHexString"])
                or (
                    m.hasStringSignature("toString(int, int)")
                    and getArgument(1).(CompileTimeConstantExpr).getIntValue() = [2, 8, 16]
                )
            )
        )
    }

    Expr getIntArgument() {
        result = getArgument(0)
    }
}

class ByteType extends Type {
    ByteType() {
        exists(PrimitiveType p |
            p = this or p = this.(BoxedType).getPrimitiveType()
        |
            p.hasName("byte")
        )
    }
}

from IntegerToStringCall toStringCall
where
    toStringCall.getIntArgument().getType() instanceof ByteType
    // Ignore if String representation is only used as part of display message
    and not exists(AddExpr concatExpr |
        concatExpr.getAnOperand() = toStringCall
        // Consider any String containing a space to be a display message
        and exists(concatExpr.getAnOperand().(StringLiteral).getRepresentedString().indexOf(" "))
    )
select toStringCall, "Does not convert byte to unsigned int before getting String representation"
