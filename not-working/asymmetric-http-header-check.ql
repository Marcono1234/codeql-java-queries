/**
 * Tries to find asymmetric HTTP header checks, e.g. on the same headers container
 * one call only retrieves the first occurence of an header and at a different
 * location another call only retrieves the last occurence of the same header.
 * An adversary could possibly exploit this by declaring the same header multiple times. 
 *
 * @kind path-problem
 */
 
/*
 * TODO:
 * Have to improve dataflow check, often not headers container is passed around,
 * but request from which headers (but same instance) are then retrieved
 */

import java
import semmle.code.java.dataflow.DataFlow
import DataFlow::PathGraph

newtype GetMode = First() or Last() or All()

abstract class GetHeaderCall extends MethodAccess {
    abstract predicate getsHeader(string name, GetMode mode);
}

/**
 * https://hc.apache.org/httpcomponents-core-ga/httpcore/apidocs/org/apache/http/HttpMessage.html
 * (4.4.13)
 */
class ApacheHttpMessageCall extends GetHeaderCall {
    Method m;
    
    ApacheHttpMessageCall() {
        m = getMethod().getAnOverride*()
        and m.getDeclaringType().hasQualifiedName("org.apache.http", "HttpMessage")
    }
    
    override predicate getsHeader(string name, GetMode mode) {
        name = getArgument(0).(CompileTimeConstantExpr).getStringValue()
        and (
            m.getName() = "getFirstHeader" and mode = First()
            or m.getName() = ["getAllHeaders", "headerIterator"] and mode = All()
            or m.getName() = "getLastHeader" and mode = Last()
        )
        or (
            name = "*" // any header
            and m.getName() = ["getAllHeaders", "headerIterator"]
            and m.getNumberOfParameters() = 0
            and mode = All()
        )
    }
}

/**
 * https://docs.oracle.com/en/java/javase/14/docs/api/java.net.http/java/net/http/HttpHeaders.html
 */
class JdkHttpHeadersCall extends GetHeaderCall {
    Method m;
    
    JdkHttpHeadersCall() {
        m = getMethod().getAnOverride*()
        and m.getDeclaringType().hasQualifiedName("java.net.http", "HttpHeaders")
    }
    
    override predicate getsHeader(string name, GetMode mode) {
        name = getArgument(0).(CompileTimeConstantExpr).getStringValue()
        and (
            m.getName() = ["firstValue", "firstValueAsLong"] and mode = First()
            or m.getName() = "allValues" and mode = All()
        )
        or (
            name = "*" // any header
            and m.getName() = "map"
            and m.getNumberOfParameters() = 0
            and mode = All()
        )
    }
}

/**
 * https://googleapis.dev/java/google-http-client/latest/com/google/api/client/http/HttpHeaders.html
 * (1.36.0)
 */
class GoogleHttpHeadersCall extends GetHeaderCall {
    Method m;
    
    GoogleHttpHeadersCall() {
        // Check generic methods and match subtypes to match java.util.Map methods as well
        getMethod().getSourceDeclaration().overridesOrInstantiates*(m)
        and exists (RefType headersType | headersType.hasQualifiedName("com.google.api.client.http", "HttpHeaders") |
            headersType.getASourceSupertype*() = m.getDeclaringType()
        )
    }
    
    override predicate getsHeader(string name, GetMode mode) {
        m.getNumberOfParameters() = 0
        and (
            mode = First()
            and exists (string mName | mName = m.getName() |
                mName = "getAccept" and name = "Accept"
                or mName = "getAcceptEncoding" and name = "Accept-Encoding"
                or mName = "getAge" and name = "Age"
                or mName = "getAuthenticate" and name = "WWW-Authenticate"
                or mName = "getAuthorization" and name = "Authorization"
                or mName = "getCacheControl" and name = "Cache-Control"
                or mName = "getContentEncoding" and name = "Content-Encoding"
                or mName = "getContentLength" and name = "Content-Length"
                or mName = "getContentMD5" and name = "Content-MD5"
                or mName = "getContentRange" and name = "Content-Range"
                or mName = "getContentType" and name = "Content-Type"
                or mName = "getCookie" and name = "Cookie"
                or mName = "getDate" and name = "Date"
                or mName = "getETag" and name = "ETag"
                or mName = "getExpires" and name = "Expires"
                or mName = "getIfMatch" and name = "If-Match"
                or mName = "getIfModifiedSince" and name = "If-Modified-Since"
                or mName = "getIfNoneMatch" and name = "If-None-Match"
                or mName = "getIfRange" and name = "If-Range"
                or mName = "getIfUnmodifiedSince" and name = "If-Unmodified-Since"
                or mName = "getLastModified" and name = "Last-Modified"
                or mName = "getLocation" and name = "Location"
                or mName = "getMimeVersion" and name = "MIME-Version"
                or mName = "getRange" and name = "Range"
                or mName = "getRetryAfter" and name = "Retry-After"
                or mName = "getUserAgent" and name = "User-Agent"
            )
            or mode = All()
            and exists (string mName | mName = m.getName() |
                mName = "getAuthenticateAsList" and name = "WWW-Authenticate"
                or mName = "getAuthorizationAsList" and name = "Authorization"
                or mName = "getWarning" and name = "Warning"
                // Map.entrySet()
                or mName = "entrySet" and name = "*" // any header
            )
        )
        or m.getNumberOfParameters() = [1 .. 2] // 2 for Map.getOrDefault
        and name = getArgument(0).(CompileTimeConstantExpr).getStringValue()
        and (
            mode = First()
            and m.getName() = "getFirstHeaderStringValue"
            or mode = All()
            and m.getName() = ["getHeaderStringValues", "get"] // Map.get(...)
        )
    }
}

/**
 * https://square.github.io/okhttp/3.x/okhttp/okhttp3/Headers.html
 * (3.14.0)
 */
class OkHttpHeadersCall extends GetHeaderCall {
    Method m;
    
    OkHttpHeadersCall() {
        m = getMethod().getAnOverride*()
        and m.getDeclaringType().hasQualifiedName("okhttp3", "Headers")
    }
    
    override predicate getsHeader(string name, GetMode mode) {
        m.getNumberOfParameters() = 1
        and name = getArgument(0).(CompileTimeConstantExpr).getStringValue()
        and (
            mode = Last()
            and m.getName() = ["get", "getDate", "getInstant"]
            or mode = All()
            and m.getName() = "values"
        )
        or name = "*" // any header
        and m.getNumberOfParameters() = 0
        and mode = All()
        and m.getName() = "toMultimap"
    }
}

/**
 * https://netty.io/4.1/api/io/netty/handler/codec/http/HttpHeaders.html
 */
class NettyHttpHeadersCall extends GetHeaderCall {
    Method m;
    
    NettyHttpHeadersCall() {
        m = getMethod().getAnOverride*()
        and m.getDeclaringType().hasQualifiedName("io.netty.handler.codec.http", "HttpHeaders")
    }
    
    // Not considering deprecated static getters here
    override predicate getsHeader(string name, GetMode mode) {
        m.getNumberOfParameters() = [1 .. 3] // 2 for default value variants; 3 for contains(...)
        and name = getArgument(0).(CompileTimeConstantExpr).getStringValue()
        and (
            mode = First()
            and m.getName() = ["get", "getInt", "getShort", "getTimeMillis", "getAsString"]
            or mode = All()
            and (
                m.getName() = ["getAll", "valueStringIterator", "valueCharSequenceIterator", "getAllAsString"]
                // Match contains(...) which checks all headers for specific value
                or m.getName() = ["contains", "containsValue"]
                and m.getNumberOfParameters() = 3
            )
        )
        or name = "*" // any header
        and m.getNumberOfParameters() = 0
        and mode = All()
        and m.getName() = ["entries, iterator", "iteratorCharSequence", "iteratorAsString"]
    }
}

/**
 * https://netty.io/4.1/api/io/netty/handler/codec/http2/Http2Headers.html
 */
class NettyHttp2HeadersCall extends GetHeaderCall {
    Method m;
    
    NettyHttp2HeadersCall() {
        // Make sure to check Http2Headers but allow also methods from Headers (= super interface)
        getReceiverType().getASourceSupertype*().hasQualifiedName("io.netty.handler.codec.http2", "Http2Headers")
        and m = getMethod().getAnOverride*()
    }
    
    override predicate getsHeader(string name, GetMode mode) {
        /* Http2Headers methods */
        m.getNumberOfParameters() = [1 .. 3] // 3 for contains(...)
        and name = getArgument(0).(CompileTimeConstantExpr).getStringValue()
        and mode = All()
        and (
            m.getName() = "valueIterator"
            // Match contains(...) which checks all headers for specific value
            or m.getName() = "contains"
            and m.getNumberOfParameters() = 3
        )
        /* Headers methods */
        or m.getNumberOfParameters() = [2 .. 3]
        and name = getArgument(0).(CompileTimeConstantExpr).getStringValue()
        and mode = All()
        // Match contains(...) which checks all headers for specific value
        and m.getName() = ["contains", "containsBoolean", "containsChar", "containsDouble", "containsFloat", "containsInt", "containsLong", "containsObject", "containsShort", "containsTimeMillis"]
        or m.getNumberOfParameters() = [1 .. 2]
        and name = getArgument(0).(CompileTimeConstantExpr).getStringValue()
        and mode = First()
        and m.getName() = ["get", "getAndRemove", "getBoolean", "getBooleanAndRemove", "getByte", "getByteAndRemove", "getChar", "getCharAndRemove", "getDouble", "getDoubleAndRemove", "getFloat", "getFloatAndRemove", "getInt", "getIntAndRemove", "getLong", "getLongAndRemove", "getShort", "getShortAndRemove", "getTimeMillis", "getTimeMillisAndRemove"]
        or m.getNumberOfParameters() = [1 .. 2]
        and name = getArgument(0).(CompileTimeConstantExpr).getStringValue()
        and mode = All()
        and m.getName() = ["getAll", "getAllAndRemove"]
        or name = "*" // any header
        and m.getNumberOfParameters() = 0
        and mode = All()
        and m.getName() = "iterator"
    }
}

class HeaderFlowConfiguration extends DataFlow::Configuration {
    HeaderFlowConfiguration() { this = "HeaderFlowConfiguration" }

    override predicate isSource(DataFlow::Node source) {
        any (GetHeaderCall call).getQualifier() = source.asExpr()
    }

    override predicate isSink(DataFlow::Node sink) {
        any (GetHeaderCall call).getQualifier() = sink.asExpr()
    }
}

from HeaderFlowConfiguration flow, DataFlow::PathNode source, GetHeaderCall sourceCall, DataFlow::PathNode sink, GetHeaderCall sinkCall
where
    source.getNode().asExpr().getParent() = sourceCall
    and sink.getNode().asExpr().getParent() = sinkCall
    and exists (string sourceName, GetMode sourceGetMode, string sinkName, GetMode sinkGetMode |
        sourceCall.getsHeader(sourceName, sourceGetMode)
        and sinkCall.getsHeader(sinkName, sinkGetMode)
        and (
            // Get same header
            sourceName.toLowerCase() = sinkName.toLowerCase()
            // Or get all headers
            or sourceName = "*" or sinkName = "*"
        )
        // Ignore if source retrieves all headers, assuming it validates them all
        and sourceGetMode != All()
        and sourceGetMode != sinkGetMode
    )
    and flow.hasFlowPath(source, sink)
select sink.getNode(), source, sink, "Asymmetric HTTP headers check"
