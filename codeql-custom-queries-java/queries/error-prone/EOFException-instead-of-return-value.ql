/**
 * Finds implementations of `read` methods which should return a value when reaching the
 * end of the data (e.g. returning the number of bytes read or -1), but instead throw
 * an `EOFException`.
 *
 * Depending on the use case, such an `EOFException` might be unexpected and callers of
 * the method might not handle it properly.
 *
 * @kind problem
 * @id TODO
 */

import java

// TODO: Deduplicate this with other queries which also define something similar? though this here focuses mainly
//   on abstract methods and not on all `read` methods (e.g. it ignores `RandomAccessFile#read`)
/**
 * `read` method which should return on EOF, but not throw an exception.
 *
 * Mainly covers abstract methods which have to be implemented by users; does not
 * cover non-abstract methods which are most likely not overridden.
 */
class ReadMethod extends Method {
  ReadMethod() {
    getDeclaringType().hasQualifiedName("java.io", "InputStream") and
    hasStringSignature([
        "available()",
        "read()",
        "read(byte[])",
        "read(byte[], int, int)",
        "readNBytes(byte[], int, int)",
        "skip(long)",
      ])
    or
    getDeclaringType().hasQualifiedName("java.io", "DataInput") and
    hasStringSignature(["skipBytes(int)",])
    or
    getDeclaringType().hasQualifiedName("java.io", "ObjectInput") and
    hasStringSignature([
        "available()",
        "read()",
        "read(byte[])",
        "read(byte[], int, int)",
        "skip(long)",
      ])
    or
    getDeclaringType().hasQualifiedName("java.lang", "Readable") and
    hasStringSignature(["read(CharBuffer)",])
    or
    getDeclaringType().hasQualifiedName("java.io", "Reader") and
    hasStringSignature([
        "read()",
        "read(char[])",
        "read(char[], int, int)",
        "skip(long)",
      ])
    or
    getDeclaringType().hasQualifiedName("java.nio.channels", "ReadableByteChannel") and
    hasStringSignature(["read(ByteBuffer)",])
    or
    getDeclaringType().hasQualifiedName("java.nio.channels", "FileChannel") and
    hasStringSignature(["read(ByteBuffer, long)",])
    or
    getDeclaringType().hasQualifiedName("java.nio.channels", "ScatteringByteChannel") and
    hasStringSignature([
        "read(ByteBuffer[])",
        "read(ByteBuffer[], int, int)",
      ])
  }
}

class EofException extends Class {
  EofException() { hasQualifiedName("java.io", "EOFException") }
}

abstract class EofThrowing extends ExprParent {
  abstract Callable getEnclosingCallable();
}

class ThrowEof extends EofThrowing, ThrowStmt {
  ThrowEof() { getThrownExceptionType().getASourceSupertype*() instanceof EofException }

  override Callable getEnclosingCallable() { result = ThrowStmt.super.getEnclosingCallable() }
}

class CallThrowsEof extends EofThrowing, Call {
  CallThrowsEof() {
    getCallee().getAThrownExceptionType().getASourceSupertype*() instanceof EofException
  }

  override Callable getEnclosingCallable() { result = Call.super.getEnclosingCallable() }
}

from Method readOverride, EofThrowing eofThrowing
where
  readOverride.getASourceOverriddenMethod+() instanceof ReadMethod and
  eofThrowing.getEnclosingCallable() = readOverride
select eofThrowing, "Throws EOFException in a method which should not throw it"
