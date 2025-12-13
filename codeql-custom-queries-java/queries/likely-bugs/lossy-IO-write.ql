/**
 * Finds calls to methods of `java.io.DataOutput`, `java.io.OutputStream` and `java.io.Writer`
 * which discard bits of the provided value to be written.
 *
 * For example `OutputStream#write(int)` has a parameter of type `int` but actually only
 * writes the lower 8 bits. That means when accidentally passing int values outside of
 * the byte value range, some of their bits will be silently ignored.
 *
 * @kind problem
 * @id TODO
 */

import java
import semmle.code.java.dataflow.DataFlow

abstract class LossyIntegralMethod extends Method {
  /** min value, inclusive */
  abstract int minValue();

  /** max value, inclusive */
  abstract int maxValue();
}

class TypeDataOutput extends Interface {
  TypeDataOutput() { hasQualifiedName("java.io", "DataOutput") }
}

abstract class LossyIntegralDataOutputMethod extends LossyIntegralMethod {
  LossyIntegralDataOutputMethod() { getDeclaringType() instanceof TypeDataOutput }
}

class DataOutputWriteByte extends LossyIntegralDataOutputMethod {
  DataOutputWriteByte() { hasStringSignature(["write(int)", "writeByte(int)"]) }

  override int minValue() { result = -128 }

  override int maxValue() { result = 127 }
}

class DataOutputWriteChar extends LossyIntegralDataOutputMethod {
  DataOutputWriteChar() { hasName("writeChar") }

  override int minValue() { result = 0 }

  override int maxValue() { result = 65535 }
}

class DataOutputWriteShort extends LossyIntegralDataOutputMethod {
  DataOutputWriteShort() { hasName("writeShort") }

  override int minValue() { result = -32768 }

  override int maxValue() { result = 32767 }
}

class OutputStreamWriteByte extends LossyIntegralMethod {
  OutputStreamWriteByte() {
    getDeclaringType().hasQualifiedName("java.io", "OutputStream") and
    hasStringSignature("write(int)")
  }

  override int minValue() { result = -128 }

  override int maxValue() { result = 127 }
}

class WriterWriteChar extends LossyIntegralMethod {
  WriterWriteChar() {
    getDeclaringType().hasQualifiedName("java.io", "Writer") and
    hasStringSignature("write(int)")
  }

  override int minValue() { result = 0 }

  override int maxValue() { result = 65535 }
}

class DataOutputWriteBytes extends Method {
  DataOutputWriteBytes() {
    getDeclaringType() instanceof TypeDataOutput and
    hasStringSignature("writeBytes(String)")
  }
}

from Expr value, MethodCall lossyCall, Method m
where
  m = lossyCall.getMethod() and
  DataFlow::localExprFlow(value, lossyCall.getAnArgument()) and
  (
    exists(LossyIntegralMethod lossyMethod, int intValue |
      m.getASourceOverriddenMethod*() = lossyMethod and
      intValue = value.(CompileTimeConstantExpr).getIntValue()
    |
      (intValue < lossyMethod.minValue() or intValue > lossyMethod.maxValue()) and
      // Ignore if value is within unsigned value range
      not (
        intValue >= 0 and
        intValue <= (lossyMethod.maxValue() - lossyMethod.minValue())
      )
    )
    or
    exists(string stringValue |
      m.getASourceOverriddenMethod*() instanceof DataOutputWriteBytes and
      stringValue = value.(CompileTimeConstantExpr).getStringValue()
    |
      // `writeBytes` only uses lower byte of each char
      stringValue.codePointAt(_) > 255
    )
  )
select lossyCall, "Lossy method call for $@", value, "this value"
