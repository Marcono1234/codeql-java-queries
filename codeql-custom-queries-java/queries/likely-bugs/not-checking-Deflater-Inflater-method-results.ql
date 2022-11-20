/**
 * Finds usage of the methods `java.util.zip.Deflater.deflate` and `java.util.zip.Inflater.inflate`
 * where the result of these methods is discarded. This can most likely result in incorrect
 * behavior because the result indicates how many output bytes were produced.
 * 
 * Depending on the zlib implementation `Inflater.inflate` might even write more data to the
 * output than what was actually inflated, see [JDK-8283758](https://bugs.openjdk.org/browse/JDK-8283758),
 * so it is even more important to check the return value of these methods.
 * 
 * @kind problem
 */

// Note: This is similar to the general "not checking return value" queries

import java

from MethodAccess call, Method m
where
    m = call.getMethod()
    and (
        m.getDeclaringType().hasQualifiedName("java.util.zip", "Deflater")
        and m.hasName("deflate")
        or
        m.getDeclaringType().hasQualifiedName("java.util.zip", "Inflater")
        and m.hasName("inflate")
    )
    // Ignore methods with ByteBuffer parameter because there the ByteBuffer can provide
    // information about how many bytes were written
    and not m.getParameterType(0).hasName("ByteBuffer")
    and call instanceof ValueDiscardingExpr
select call, "Should check return value of call"
