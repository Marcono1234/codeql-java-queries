/**
 * Finds code which calls a stream reading method, such as `InputStream#read()`,
 * casts the result to a smaller numeric type such as `byte` and afterwards
 * checks for end-of-file by comparing the value against `-1`.
 *
 * This can lead to an erroneously detected end-of-file because due to the cast
 * the max unsigned value of the target type, e.g. the byte value 255, becomes
 * -1 as well. Instead the code should first check for -1 and only afterwards
 * perform the cast.
 *
 * For example:
 * ```java
 * // BAD
 * byte b = (byte) in.read();
 * if (b == -1) ...
 *
 * // GOOD
 * int read = in.read();
 * if (read == -1) ...
 * byte b = (byte) read;
 * ```
 *
 * This query was inspired by <https://github.com/openjdk/jdk/pull/30357>.
 *
 * @kind problem
 * @id TODO
 */

import java
import semmle.code.java.dataflow.DataFlow

class CastTargetType extends Type {
  CastTargetType() {
    this.hasName(["byte", "char", "short"]) or
    this.(Class).hasQualifiedName("java.lang", ["Byte", "Character", "Short"])
  }
}

// Checks for flow from a method returning an `int`, to conversion to `byte` and comparison with `-1`
from MethodCall readCall, EqualityTest eofCheck, Expr castedExpr
where
  readCall.getType().hasName("int") and
  DataFlow::localExprFlow(readCall, castedExpr) and
  // Assumes that dataflow implicitly continues through cast to `byte`
  castedExpr.getType() instanceof CastTargetType and
  eofCheck.getAnOperand() = castedExpr and
  // Don't check for CompileTimeConstantExpr because that would also include values such as `0xFF` or constants which do not represent EOF
  eofCheck.getAnOperand().(MinusExpr).getExpr().(IntegerLiteral).getIntValue() = 1
select eofCheck, "Incorrect end-of-file check after cast"
