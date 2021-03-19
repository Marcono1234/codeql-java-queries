/**
 * Finds calls to `InputStream.skip(long)` which either ignore the
 * return value or only compare it with an expected skip value.
 * However, as described in the documentation for the method:
 * > The skip method may, for a variety of reasons, end up skipping
 * > over some smaller number of bytes, possibly 0.
 *
 * Therefore the caller must check the return value and calculate
 * the remaining number of bytes to skip, or when using Java 12 or
 * higher prefer the method `InputStream.skipNBytes(long)` instead.
 */
// Partially covered by QL's java/ignored-error-status-of-call query

import java
import lib.Expressions

class SkipMethod extends Method {
    SkipMethod() {
        getDeclaringType().getASourceSupertype*().hasQualifiedName("java.io", "InputStream")
        and hasStringSignature("skip(long)")
    }
}

from MethodAccess skipCall
where
    skipCall.getMethod() instanceof SkipMethod
    and (
        skipCall instanceof StmtExpr // Ignores return value
        or skipCall.getParent() instanceof ComparisonExpr
        or skipCall.getParent() instanceof EqualityTest
    )
select skipCall, "Return value of skip call is not used"
