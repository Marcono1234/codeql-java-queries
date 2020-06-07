/**
 * Finds integer literals which are used in binary operations,
 * but are written in decimal notation making it difficult to
 * see which bits are set.
 * For better readability the literal should be written in
 * binary (prefix `0b`), octal (prefix `0`) or
 * hexadecimal (prefix `0x`) notation instead.
 */

import java

class BitExpr extends BitwiseExpr {
    Expr getAnOperand() {
        result = this.(BinaryExpr).getAnOperand()
        or result = this.(UnaryExpr).getExpr()
    }
}

class DecimalIntegerLiteral extends IntegerLiteral {
    DecimalIntegerLiteral() {
        not (
            // Hexadecimal
            (
                getLiteral().indexOf("0x") = 0
                or getLiteral().indexOf("0X") = 0
            )
            // Binary
            or (
                getLiteral().indexOf("0b") = 0
                or getLiteral().indexOf("0B") = 0
            )
            // Octal
            or (
                getLiteral().indexOf("0") = 0
                and getIntValue() != 0
            )
        )
    }
}

bindingset[i]
predicate isPowerOf2(int i) {
    i.bitAnd(i - 1) = 0
}

bindingset[i]
predicate hasUnderstandableBitPattern(int i) {
    i >= -1 // Negative other than -1 is uncommon
    // 65536 = 2^16, everything higher is uncommon
    // Except 2147483647, which is Integer.MAX_VALUE
    and (i <= 65536 or i = 2147483647)
    and (
        i < 10
        or isPowerOf2(i)
        // One less than power of 2 means all bits set
        or isPowerOf2(i + 1)
    )
}

from BitExpr bitExpr, DecimalIntegerLiteral intLiteral
where
    (
        intLiteral = bitExpr.getAnOperand()
        // Expr initializes field which is accessed in bit expr
        or exists (Field f |
            f.getInitializer() = intLiteral
            and bitExpr.getAnOperand() = f.getAnAccess()
        )
    )
    and not hasUnderstandableBitPattern(intLiteral.getIntValue())
    // hashCode() might use uncommon prime numbers
    and not bitExpr.getEnclosingCallable().hasStringSignature("hashCode()")
select intLiteral, bitExpr
