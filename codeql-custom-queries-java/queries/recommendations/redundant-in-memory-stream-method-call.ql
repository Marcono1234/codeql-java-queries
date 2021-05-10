/**
 * Finds implicit (through try-with-resources) and explicit method calls of
 * in-memory stream types (such as `StringWriter`) which have no effect.
 * E.g.:
 * ```java
 * // Redundant usage of try-with-resources because ByteArrayInputStream.close()
 * // has no effect
 * try (ByteArrayInputStream in = new ByteArrayInputStream(...)) {
 *     ...
 * }
 * ```
 * 
 * Note that some of the results might be false positives in case custom
 * subclasses are used which override the methods in question.
 */

import java


abstract class InMemoryInputStream extends Class {
}

abstract class InMemoryReader extends Class {
}

class TypeStringReader extends InMemoryReader {
    TypeStringReader() {
        hasQualifiedName("java.io", "StringReader")
    }
}

class TypeCharArrayReader extends InMemoryReader {
    TypeCharArrayReader() {
        hasQualifiedName("java.io", "CharArrayReader")
    }
}

abstract class InMemoryStream extends Class {
}

class TypeByteArrayInputStream extends InMemoryStream, InMemoryInputStream {
    TypeByteArrayInputStream() {
        hasQualifiedName("java.io", "ByteArrayInputStream")
    }
}

abstract class FlushableInMemoryStream extends InMemoryStream {
}

class TypeByteArrayOutputStream extends FlushableInMemoryStream {
    TypeByteArrayOutputStream() {
        hasQualifiedName("java.io", "ByteArrayOutputStream")
    }
}

class TypeCharArrayWriter extends FlushableInMemoryStream {
    TypeCharArrayWriter() {
        hasQualifiedName("java.io", "CharArrayWriter")
    }
}

class TypeStringWriter extends FlushableInMemoryStream {
    TypeStringWriter() {
        hasQualifiedName("java.io", "StringWriter")
    }
}

// Do not include StringReader because its `close()` method prevents subsequent usage
// which might be desired in some cases

private predicate isNoopCall(MethodAccess call) {
    // Ignore custom subtypes because they might implement these methods differently
    (
        call.getReceiverType() instanceof InMemoryStream
        and call.getMethod().hasStringSignature("close()")
    )
    or (
        call.getReceiverType() instanceof FlushableInMemoryStream
        and call.getMethod().hasStringSignature("flush()")
    )
}

private Expr getAResourceExpr(TryStmt try) {
    // Cannot simply use getAResourceVariable() because that would get wrong type
    // when variable type is supertype of init, e.g. `Reader r = new StringReader(...)`
    result = try.getAResourceExpr()
    or result = try.getAResourceDecl().getAVariable().getInit()
}

/*
 * Note: For now don't consider calling InputStream.available() or Reader.ready();
 * in some cases they might be replacable with direct calls to read(), but in
 * other cases they can improve readability compared to reading, storing the result
 * and checking its value (e.g. `(b = stream.read()) != -1`).
 */

from Top noopStreamTop, string message
where
    // Calling markSupported() on in-memory InputStream or Reader
    exists(MethodAccess markSupportedCall | noopStreamTop = markSupportedCall |
        (
            markSupportedCall.getReceiverType() instanceof InMemoryReader
            or markSupportedCall.getReceiverType() instanceof InMemoryInputStream
        )
        and markSupportedCall.getMethod().hasStringSignature("markSupported()")
        and message = "Redundant call because markSupported() always returns true for this type"
    )
    // try-with-resources implicitly invoking `close()`
    // Only report if all resources are in-memory streams, otherwise for consistency it does
    // not hurt to declare in-memory streams as resources if there are non-in-memory streams as well
    or (
        // `forex` instead of `forall` because there has to exist at least one resource
        forex(Expr resourceExpr | resourceExpr = getAResourceExpr(noopStreamTop) |
            resourceExpr.getType() instanceof InMemoryStream
        )
        and message = "Redundant resources in try-with-resources; for all resource types close() has no effect"
    )
    // Or explicit method call
    or (
        isNoopCall(noopStreamTop)
        and message = "Redundant call because this method has no effect for this type"
    )
select noopStreamTop, message
