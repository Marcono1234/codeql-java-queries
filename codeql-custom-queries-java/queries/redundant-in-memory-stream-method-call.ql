/**
 * Finds implicit (through try-with-resources) and explicit method calls of
 * in-memory stream types (such as `StringWriter`) which have no effect.
 * E.g.:
 * ```
 * // Redundant usage of try-with-resources because ByteArrayInputStream.close()
 * // has no effect
 * try (ByteArrayInputStream in = new ByteArrayInputStream(...)) {
 *     ...
 * }
 * ```
 */

import java

abstract class InMemoryStream extends Class {
}

abstract class FlushableInMemoryStream extends InMemoryStream {
}

class TypeByteArrayInputStream extends InMemoryStream {
    TypeByteArrayInputStream() {
        hasQualifiedName("java.io", "ByteArrayInputStream")
    }
}

class TypeByteArrayOutputStream extends FlushableInMemoryStream {
    TypeByteArrayOutputStream() {
        hasQualifiedName("java.io", "ByteArrayOutputStream")
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

from Top noopStreamTop, string message
where
    // try-with-resources implicitly invoking `close()`
    // Only report if all resources are in-memory streams, otherwise for consistency it does
    // not hurt to declare in-memory streams as resources if there are non-in-memory streams as well
    (
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
