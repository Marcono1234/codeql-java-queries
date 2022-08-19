/**
 * Finds code which calls one of the `read` methods of `InputStream` or `Reader` but does not
 * check for the return value of `-1` which indicates the end of stream. This can lead to
 * incorrect behavior, such as corrupted data or causing execution to get stuck in an infinite
 * loop.
 * 
 * @kind problem
 */

import java
import semmle.code.java.dataflow.DataFlow

import lib.Expressions

class ReadMethod extends Method {
    ReadMethod() {
        (
            getDeclaringType().hasQualifiedName("java.io", "InputStream")
            and (
                hasStringSignature("read()")
                or hasStringSignature("read(byte[])")
                or hasStringSignature("read(byte[], int, int)")
                or hasStringSignature("readNBytes(byte[], int, int)")
            )
        )
        or (
            getDeclaringType().hasQualifiedName("java.io", "Reader")
            and (
                hasStringSignature("read()")
                or hasStringSignature("read(char[])")
                or hasStringSignature("read(char[], int, int)")
            )
        )
    }
}

predicate isReadLenCheckArg(Expr expr) {
    // Consider both `!= -1` and `== -1`
    exists (EqualityTest eqTest |
        eqTest.getAnOperand() = expr
        and eqTest.getAnOperand().(CompileTimeConstantExpr).getIntValue() = -1
    )
    // Or checks >= 0 or >= 1 or similar
    or comparesWithConstant(_, expr, [0, 1], _)
}

from MethodAccess call
where
    call.getMethod().getSourceDeclaration().getASourceOverriddenMethod*() instanceof ReadMethod
    and not exists(Expr readLenCheckArg |
        isReadLenCheckArg(readLenCheckArg)
        and DataFlow::localExprFlow(call, readLenCheckArg)
    )
    and not DataFlow::localExprFlow(call, any(ReturnStmt s).getResult())
select call, "Should check result for -1"
