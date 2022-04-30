/**
 * Finds usage of `Stream` or the primitive stream variants where first the elements
 * are filtered and then it is checked whether any element exists. Such code can be
 * simplified by directly using the stream methods `anyMatch` or `noneMatch`.
 * 
 * For example:
 * ```java
 * stream.filter(s -> s.length() > 2).findAny().isPresent()
 * ```
 * Can be simplified to:
 * ```java
 * stream.anyMatch(s -> s.length() > 2)
 * ```
 */

import java

// BaseStream is the superinterface of Stream and primitive stream types
class TypeBaseStream extends Interface {
    TypeBaseStream() {
        hasQualifiedName("java.util.stream", "BaseStream")
    }
}

class StreamFilterMethod extends Method {
    StreamFilterMethod() {
        getDeclaringType().getSourceDeclaration().getASourceSupertype*() instanceof TypeBaseStream
        and hasName("filter")
    }
}

class StreamFindMethod extends Method {
    StreamFindMethod() {
        getDeclaringType().getSourceDeclaration().getASourceSupertype*() instanceof TypeBaseStream
        and hasStringSignature(["findFirst()", "findAny()"])
    }
}

class OptionalPresentCheckMethod extends Method {
    boolean polarity;

    OptionalPresentCheckMethod() {
        getDeclaringType().getSourceDeclaration().getASourceSupertype*().hasQualifiedName("java.util", ["Optional", "OptionalDouble", "OptionalInt", "OptionalLong"])
        and (
            hasStringSignature("isPresent()") and polarity = true
            or hasStringSignature("isEmpty()") and polarity = false
        )
    }

    /**
     * Gets the polarity; `true` if the method tests if the value is present, `false` if
     * it tests if the value is absent.
     */
    boolean polarity() {
        result = polarity
    }
}

from MethodAccess streamFilterCall, MethodAccess streamFindCall, MethodAccess optionalPresentCheckCall, OptionalPresentCheckMethod optionalPresentCheckMethod, string alternative
where
    streamFilterCall.getMethod() instanceof StreamFilterMethod
    and streamFindCall.getQualifier() = streamFilterCall
    and streamFindCall.getMethod() instanceof StreamFindMethod
    and optionalPresentCheckCall.getQualifier() = streamFindCall
    and optionalPresentCheckMethod = optionalPresentCheckCall.getMethod()
    and if (optionalPresentCheckMethod.polarity() = true) then alternative = "anyMatch"
    else alternative = "noneMatch"
select streamFilterCall, "Could replace this with a `Stream." + alternative + "` call"
