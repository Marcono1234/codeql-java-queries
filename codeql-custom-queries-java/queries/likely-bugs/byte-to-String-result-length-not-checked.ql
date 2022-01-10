/**
 * Finds creation of a binary, octal or hexadecimal String from a byte
 * value using one of the `Integer` methods but where the length of the
 * result is not checked, or usage of a `Formatter` pattern which does
 * not specify a width.
 * Such conversion to String will not emit a fixed amount of characters.
 * It is therefore necessary to check the result length, respectively
 * use a Formatter pattern with a _width_ value.
 * E.g.:
 * ```java
 * public static String toHex(byte[] bytes) {
 *     StringBuilder sb = new StringBuilder(bytes.length * 2);
 *     for (byte b : bytes) {
 *         // BAD: For values < 16 this will only add a single hex char
 *         sb.append(Integer.toHexString(b & 0xFF));
 *     }
 *     return sb.toString();
 * }
 * 
 * public static toHexUsingFormatter(byte[] bytes, PrintStream out) {
 *     for (byte b : bytes) {
 *         // BAD: For values < 16 this will only add a single hex char
 *         out.printf("%x", b);
 *     }
 * }
 * ```
 * The correct implementation would be:
 * ```java
 * public static String toHex(byte[] bytes) {
 *     StringBuilder sb = new StringBuilder(bytes.length * 2);
 *     for (byte b : bytes) {
 *         int unsignedB = b & 0xFF;
 *         if (unsignedB < 16) {
 *             sb.append('0');
 *         }
 *         sb.append(Integer.toHexString(unsignedB));
 *     }
 *     return sb.toString();
 * }
 * 
 * public static toHexUsingFormatter(byte[] bytes, PrintStream out) {
 *     for (byte b : bytes) {
 *         // Uses width 2, padding smaller values with '0'
 *         out.printf("%02x", b);
 *     }
 * }
 * ```
 * 
 * Alternatively `java.util.HexFormat` added in Java 17 or similar
 * classes from third-party libraries could be used.
 */

import java
import semmle.code.java.StringFormat
import semmle.code.java.dataflow.DataFlow

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

from MethodAccess toStringCall, string message
where
    (
        // Argument is likely `b & 0xFF` (or similar) to get unsigned value
        exists(AndBitwiseExpr andExpr |
            toStringCall.(IntegerToStringCall).getIntArgument() = andExpr
            and andExpr.getAnOperand().getType() instanceof ByteType
            // Verify that value is 255 (0xFF), ignore if for example 0x0F
            and andExpr.getAnOperand().(CompileTimeConstantExpr).getIntValue() = 255
            // And length of result is not checked
            and not exists(MethodAccess lengthCall | lengthCall.getMethod() instanceof StringLengthMethod |
                DataFlow::localExprFlow(toStringCall, lengthCall.getQualifier())
            )
            and message = "Does not check length of String representation"
        )
        or exists(FormattingCall formattingCall | formattingCall = toStringCall |
            // Does not specify width and padding (should use "%02x")
            formattingCall.getAFormatString() = ["%x", "%X"]
            and formattingCall.getAnArgumentToBeFormatted().getType() instanceof ByteType
            and message = "Should specify width and padding (\"%02x\")"
        )
    )
    // Ignore if String representation is only used as part of display message
    and not exists(AddExpr concatExpr |
        concatExpr.getAnOperand() = toStringCall
        // Consider any String containing a space to be a display message
        and exists(concatExpr.getAnOperand().(StringLiteral).getValue().indexOf(" "))
    )
select toStringCall, message
