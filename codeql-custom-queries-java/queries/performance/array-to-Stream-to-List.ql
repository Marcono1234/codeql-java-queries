/**
 * Finds code which first creates a `Stream` for an array (or varargs arguments) just to
 * directly afterwards call `collect(Collectors.toList())` on it. Such code should be
 * simplified by using `java.util.Arrays.asList(...)` instead, especially because
 * `Collectors.toList()` makes no guarantees about the type of the created list, so there
 * is really no advantage of using it over `Arrays.asList`.
 * 
 * @kind problem
 */

import java

class StreamFromArrayMethod extends Method {
    StreamFromArrayMethod() {
        (
            getDeclaringType().hasQualifiedName("java.util", "Arrays")
            // Only consider method which accepts object array (ignore primitive ones), and only
            // the one without start and end index
            and hasStringSignature("stream(T[])")
        )
        or (
            getDeclaringType().hasQualifiedName("java.util.stream", "Stream")
            // Only consider method which accepts an array (respectively varargs)
            and hasStringSignature("of(T[])") 
        )
    }
}

class StreamCollectMethod extends Method {
    StreamCollectMethod() {
        getDeclaringType().hasQualifiedName("java.util.stream", "Stream")
        and hasName("collect")
        and getNumberOfParameters() = 1
    }
}

class CollectorsToListMethod extends Method {
    CollectorsToListMethod() {
        getDeclaringType().hasQualifiedName("java.util.stream", "Collectors")
        and hasStringSignature("toList()")
    }
}

from MethodAccess streamCreationCall, MethodAccess collectCall
where
    streamCreationCall.getMethod() instanceof StreamFromArrayMethod
    and streamCreationCall = collectCall.getQualifier()
    and collectCall.getMethod().getSourceDeclaration().getASourceOverriddenMethod*() instanceof StreamCollectMethod
    // Note: Don't cover `Stream.toList()` because that makes guarantees about the list, such as it being unmodifiable
    and collectCall.getArgument(0).(MethodAccess).getMethod() instanceof CollectorsToListMethod
select collectCall, "Should use `Arrays.asList(...)` instead"
