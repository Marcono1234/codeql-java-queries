/**
 * Finds creation of file paths based on a URL encoded path, for example
 * `URL.getPath()`. Such code will not work correctly when the path contains
 * characters which are URL encoded, such as spaces or non-ASCII characters,
 * because the characters will not be decoded in the file path. E.g.:
 * ```java
 * File getFile(URL url) {
 *     // Bad: `URL.getPath()` is URL encoded
 *     return new File(url.getPath()));
 * }
 * ```
 * 
 * Instead the `URL` should by converted to a `URI` by calling `toURI()`
 * and then the respective method or constructor accepting a URI should be
 * used, for example `File(URI)` or `Path.of(URI)` (for this method it might
 * be necessary to verify that the scheme is `file`).
 * 
 * However, creating a file path from a URL encoded path can be used as
 * fallback in case `URL.toURI()` throws an exception (e.g. when it contains
 * an unencoded space character).
 */

import java
import semmle.code.java.security.PathCreation
import semmle.code.java.dataflow.DataFlow

abstract class EncodedPathMethod extends Method {
}

class UrlEncodedPathMethod extends EncodedPathMethod {
    UrlEncodedPathMethod() {
        getDeclaringType().hasQualifiedName("java.net", "URL")
        and hasName(["getFile", "getPath"])
        and hasNoParameters()
    }
}

class UriEncodedPathMethod extends EncodedPathMethod {
    UriEncodedPathMethod() {
        getDeclaringType().hasQualifiedName("java.net", "URI")
        and hasName("getRawPath")
        and hasNoParameters()
    }
}

from MethodAccess encodedPathCall, PathCreation pathCreation
where
    encodedPathCall.getMethod() instanceof EncodedPathMethod
    and DataFlow::localExprFlow(encodedPathCall, pathCreation.getAnInput())
select encodedPathCall, "URL encoded path is used $@ to create a file path", pathCreation, "here"
