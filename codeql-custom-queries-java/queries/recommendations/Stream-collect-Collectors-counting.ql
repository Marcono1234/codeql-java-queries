/**
 * Finds `Stream` usage where the count of the elements is determined with
 * `stream.collect(Collectors.counting())`. This can be simplified by directly
 * using `Stream.count()`, which most likely also has better performance.
 * 
 * This query is based on Effective Java, Third Edition:
 * "Item 46: Prefer side-effect-free functions in streams"
 *
 * @kind problem
 */

import java

class StreamCollectMethod extends Method {
    StreamCollectMethod() {
        getDeclaringType().hasQualifiedName("java.util.stream", "Stream")
        and hasName("collect")
    }
}

class CollectorsCountingMethod extends Method {
    CollectorsCountingMethod() {
        getDeclaringType().hasQualifiedName("java.util.stream", "Collectors")
        and hasStringSignature("counting()")
    }
}

from MethodAccess collectCall, MethodAccess countingCollectorCall
where
    collectCall.getMethod().getSourceDeclaration().getASourceOverriddenMethod*() instanceof StreamCollectMethod
    and collectCall.getArgument(0) = countingCollectorCall
    and countingCollectorCall.getMethod() instanceof CollectorsCountingMethod
select countingCollectorCall, "Should use Stream.count() instead"
