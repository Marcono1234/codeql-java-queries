/**
 * Finds calls to `read` methods of `InputStream` and `Reader` where the number of
 * read bytes or chars is not used. Such code might be error-prone because the `read`
 * methods might read less than the requested number of bytes or chars.
 * 
 * @kind problem
 */

// Overlaps with CodeQL's java/ignored-error-status-of-call

// Note: This is different than "error-prone/not-checking-end-of-stream-read-result.ql"
// because this query also catches cases like `if (read(...) != -1)` where a end of stream
// check exists, but read result len is ignored

import java

/**
 * `read` method which returns the number of read bytes or chars.
 */
class ReadMethod extends Method {
    ReadMethod() {
        (
            getDeclaringType().hasQualifiedName("java.io", "InputStream")
            and (
                hasStringSignature("read(byte[])")
                or hasStringSignature("read(byte[], int, int)")
                or hasStringSignature("readNBytes(byte[], int, int)")
                or hasStringSignature("skip(long)")
            )
        )
        or (
            getDeclaringType().hasQualifiedName("java.io", "Reader")
            and (
                hasStringSignature("read(char[])")
                or hasStringSignature("read(char[], int, int)")
                or hasStringSignature("skip(long)")
            )
        )
    }
}

from MethodAccess readCall
where
    readCall.getMethod().getSourceDeclaration().getASourceOverriddenMethod*() instanceof ReadMethod
    and not any(VariableAssign a).getSource() = readCall
    // Note: Using AssignOp is a bit questionable because it does not check for -1, but that is covered
    // by a separate query
    and not any(AssignOp a).getRhs() = readCall
    and not any(ReturnStmt s).getResult() = readCall
select readCall, "Does not properly use read result length"
