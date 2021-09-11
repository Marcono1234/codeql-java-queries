/**
 * Finds creation of a buffer array used for reading or writing data, which is
 * created inside the loop in which it is used. It might be better to only create
 * the array once outside the loop for better performance. For example:
 * ```java
 * while (true) {
 *     // Buffer should be created outside the loop
 *     byte[] buffer = new byte[2048];
 *     int read = stream.read(buffer);
 *     if (read < 0) {
 *         break;
 *     }
 * 
 *     ...
 * }
 * ```
 */

import java
import semmle.code.java.dataflow.DataFlow
import lib.Loops

// Note: The covered methods are based on JDK 16

abstract class ReadingOrWritingMethod extends Method {
    abstract int getBufferParamIndex();
}

class ReadingMethod extends ReadingOrWritingMethod {
    int bufferParamIndex;

    ReadingMethod() {
        exists(string type, string name |
            type = getDeclaringType().getSourceDeclaration().getASourceSupertype*().getQualifiedName()
            and name = getName()
        |
            bufferParamIndex = 0 and (
                type = "java.io.Reader" and name = "read"
                or type = "java.io.InputStream" and name = ["read", "readNBytes"]
                or type = "java.io.DataInput" and name = "readFully"
                or type = "java.io.RandomAccessFile" and name = "read"
                or type = "javax.imageio.stream.ImageInputStream" and name = ["read", "readFully"]
            )
            or bufferParamIndex = [0, 1] and (
                // Buffer subclasses with relative and absolute `get` method
                type = "java.nio.Buffer" and name = "get"
            )
            or bufferParamIndex = [0, 1]
            and type = "java.util.Base64.Decoder" and name = "decode"
        )
        and getParameterType(bufferParamIndex) instanceof Array
    }

    override
    int getBufferParamIndex() {
        result = bufferParamIndex
    }
}

class WritingMethod extends ReadingOrWritingMethod {
    int bufferParamIndex;

    WritingMethod() {
        exists(string type, string name |
            type = getDeclaringType().getSourceDeclaration().getASourceSupertype*().getQualifiedName()
            and name = getName()
        |
            bufferParamIndex = 0 and (
                type = "java.io.Writer" and name = "write"
                or type = "java.io.OutputStream" and name = "write"
                or type = "java.io.DataOutput" and name = "write"
                or type = "java.io.ByteArrayOutputStream" and name = "writeBytes"
                or type = "java.io.PrintStream" and name = ["print", "println", "writeBytes"]
                or type = "java.io.PrintWriter" and name = ["print", "println"]
                or type = "javax.imageio.stream.ImageOutputStream" and name = ["writeChars", "writeDoubles", "writeFloats", "writeInts", "writeLongs", "writeShorts"]
            )
            or bufferParamIndex = [0, 1] and (
                // Buffer subclasses with relative and absolute `put` method
                type = "java.nio.Buffer" and name = "put"
            )
            or bufferParamIndex = [0, 1]
            and type = "java.util.Base64.Encoder" and name = ["encode", "encodeToString"]
        )
        and getParameterType(bufferParamIndex) instanceof Array
    }

    override
    int getBufferParamIndex() {
        result = bufferParamIndex
    }
}

from LoopStmt loop, ArrayCreationExpr arrayCreation, LocalScopeVariable arrayVariable, MethodAccess readingOrWritingCall
where
    arrayVariable.getInitializer() = arrayCreation
    and exists(LocalVariableDeclStmt variableDeclaration |
        variableDeclaration.getAVariable().getVariable() = arrayVariable
        and variableDeclaration.getEnclosingStmt() = loop.getBody()
    )
    and readingOrWritingCall.getAnEnclosingStmt() = loop.getBody()
    and exists(ReadingOrWritingMethod readingOrWritingMethod |
        readingOrWritingCall.getMethod() = readingOrWritingMethod
        and readingOrWritingCall.getArgument(readingOrWritingMethod.getBufferParamIndex()) = arrayVariable.getAnAccess()
    )
    // And array creation does not use variable which only exists in loop body
    and not exists(LocalVariableDeclExpr referencedVariable |
        referencedVariable.getAnEnclosingStmt() = loop.getBody()
        and arrayCreation.getAChildExpr+() = referencedVariable.getAnAccess()
    )
    // And array is not created with dynamically determined size or content
    and not exists(MethodAccess readCall |
        readCall.getMethod().getName().matches(["read%", "remaining"])
        // Don't check `getBody()` to also cover call in loop condition
        and readCall.getAnEnclosingStmt() = loop
        and DataFlow::localExprFlow(readCall, arrayCreation.getAChildExpr())
    )
    // And read or write call is not inside a nested loop
    and not exists(LoopStmt otherLoop |
        otherLoop.getEnclosingStmt() = loop.getBody()
        // Don't check `getBody()` to also cover usage in loop condition
        and readingOrWritingCall.getAnEnclosingStmt() = otherLoop
    )
    // And loop is not exited after reading or writing call
    and not exists(Stmt exitingStmt |
        exitingStmt = getAnExitingStatement(loop)
        and readingOrWritingCall.getControlFlowNode().getASuccessor*() = exitingStmt
        // And exiting statement occurs afterwards, and not in the next iteration of the loop
        and exitingStmt.getLocation().getStartLine() >= readingOrWritingCall.getLocation().getEndLine()
    )
select arrayCreation, "Should move buffer array creation for $@ call outside of $@ loop",
    readingOrWritingCall, "this", loop, "this"
