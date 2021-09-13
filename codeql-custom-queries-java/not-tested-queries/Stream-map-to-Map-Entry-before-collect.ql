/**
 * Finds `java.util.stream.Stream` usage where first elements are mapped
 * to `Map.Entry` and then collected to a `Map`.
 * 
 * It might be easier and more performant to use the convenience collectors
 * defined by `java.util.stream.Collectors`, such as `toMap`, which allow
 * directly creating map keys and values and collecting them to a `Map`.
 */

// TODO: Not tested

// TODO: Use query library file for Stream classes and methods

// TODO: Also cover mapToObject methods of primitive streams

import java

class TypeStream extends Interface {
  TypeStream() {
    hasQualifiedName("java.util.stream", "Stream")
  }
}

class StreamMapMethod extends Method {
  StreamMapMethod() {
    getDeclaringType().getSourceDeclaration().getASourceSupertype*() instanceof TypeStream
    and hasName("map")
  }
}

class StreamCollectMethod extends Method {
  StreamCollectMethod() {
    getDeclaringType().getSourceDeclaration().getASourceSupertype*() instanceof TypeStream
    and hasName("collect")
  }
}

class TypeMap extends Interface {
  TypeMap() {
    hasQualifiedName("java.util", "Map")
  }
}

class MapEntryConstructingCallable extends Callable {
  MapEntryConstructingCallable() {
    this.(Constructor).getDeclaringType().getSourceDeclaration().hasQualifiedName("java.util.AbstractMap", [
      "SimpleEntry",
      "SimpleImmutableEntry"
    ])
    // Static factory method Map.entry(K, V)
    or exists(Method m | m = this |
      m.getDeclaringType() instanceof TypeMap
      and m.hasName("entry")
    )
  }
}

// Note: Only consider lambda because it is easier to refactor than method referenced from method
// reference expression or class implementing Function
from MethodAccess streamMapCall, LambdaExpr mappingLambda, Call mapEntryConstructingCall, MethodAccess streamCollectCall
where
  streamMapCall.getMethod() instanceof StreamMapMethod
  and mappingLambda = streamMapCall.getArgument(0)
  and mapEntryConstructingCall.getEnclosingCallable() = mappingLambda.asMethod()
  and mapEntryConstructingCall.getCallee() instanceof MapEntryConstructingCallable
  and streamCollectCall.getMethod() instanceof StreamCollectMethod
  and streamCollectCall.getQualifier() = streamMapCall
  and streamCollectCall.getType().(RefType).getSourceDeclaration().getASourceSupertype*() instanceof TypeMap
select streamMapCall, "Redundant mapping to Map.Entry; $@ collection step should directly create Map entries", streamCollectCall, "this"
