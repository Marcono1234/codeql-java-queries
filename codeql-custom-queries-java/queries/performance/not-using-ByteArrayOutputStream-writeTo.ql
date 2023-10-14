/**
 * Finds usage of `ByteArrayOutputStream` where the written data is obtained
 * using `toByteArray()` and then later written to another `OutputStream`.
 * In these cases `ByteArrayOutputStream.writeTo` should be preferred because
 * unlike `toByteArray()` it avoids creating a copy of the internal buffer.
 *
 * @kind problem
 */

import java
import semmle.code.java.dataflow.DataFlow

class ToByteArrayMethod extends Method {
  ToByteArrayMethod() {
    getDeclaringType().hasQualifiedName("java.io", "ByteArrayOutputStream") and
    hasStringSignature("toByteArray()")
  }
}

class OutputStreamWriteMethod extends Method {
  OutputStreamWriteMethod() {
    getDeclaringType().getASourceSupertype*().hasQualifiedName("java.io", "OutputStream") and
    hasStringSignature("write(byte[])")
  }
}

from MethodAccess toByteArrayCall, MethodAccess writeCall
where
  toByteArrayCall.getMethod() instanceof ToByteArrayMethod and
  writeCall.getMethod() instanceof OutputStreamWriteMethod and
  // TODO: Using dataflow causes some false positives when array is additionally used in other ways
  DataFlow::localExprFlow(toByteArrayCall, writeCall.getArgument(0))
select toByteArrayCall,
  "Could use `ByteArrayOutputStream.writeTo` instead of manually writing to `OutputStream` $@",
  writeCall, "here"
