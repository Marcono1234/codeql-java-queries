/**
 * Finds conversion of an array or a `Collection<CharSequence>` to a `Stream`
 * just to join the elements to a single string. Such code can be simplified
 * by using `String.join`. For example:
 * ```java
 * List<String> words = ...;
 * String sentence = words.stream().collect(Collectors.joining(" "));
 *
 * // Can be simplified as
 * String sentence = String.join(" ", words);
 * ```
 *
 * @kind problem
 */

import java

class CollectionStreamMethod extends Method {
  CollectionStreamMethod() {
    getDeclaringType().hasQualifiedName("java.util", "Collection") and
    hasStringSignature("stream()")
  }
}

class ArrayAsStreamMethod extends Method {
  ArrayAsStreamMethod() {
    isStatic() and
    (
      getDeclaringType().hasQualifiedName("java.util", "Arrays") and
      hasName("stream")
      or
      getDeclaringType().hasQualifiedName("java.util.stream", "Stream") and
      hasName("of")
    )
  }
}

class CollectMethod extends Method {
  CollectMethod() {
    getDeclaringType().hasQualifiedName("java.util.stream", "Stream") and
    hasName("collect")
  }
}

class JoiningCollectorMethod extends Method {
  JoiningCollectorMethod() {
    getDeclaringType().hasQualifiedName("java.util.stream", "Collectors") and
    hasName("joining") and
    // Ignore variant with additional prefix and suffix arguments
    getNumberOfParameters() = [0, 1]
  }
}

from
  Expr collectionExpr, MethodAccess charSeqStreamExpr, MethodAccess collectCall,
  MethodAccess joiningCall
where
  (
    exists(MethodAccess collectionStreamCall | charSeqStreamExpr = collectionStreamCall |
      collectionStreamCall.getQualifier() = collectionExpr and
      collectionStreamCall.getMethod().getSourceDeclaration().getASourceOverriddenMethod*()
        instanceof CollectionStreamMethod
    )
    or
    exists(MethodAccess arrayStreamCall | charSeqStreamExpr = arrayStreamCall |
      arrayStreamCall.getArgument(0) = collectionExpr and
      arrayStreamCall.getMethod() instanceof ArrayAsStreamMethod
    )
  ) and
  // Has type Stream<CharSequence>
  charSeqStreamExpr
      .getType()
      .(ParameterizedType)
      .getTypeArgument(0)
      .getErasure()
      .(RefType)
      .getASourceSupertype*()
      .hasQualifiedName("java.lang", "CharSequence") and
  // Calls `stream.collect(...)`
  collectCall.getQualifier() = charSeqStreamExpr and
  collectCall.getMethod().getSourceDeclaration().getASourceOverriddenMethod*() instanceof
    CollectMethod and
  // Calls `collect(Collectors.joining(...))`
  collectCall.getArgument(0) = joiningCall and
  joiningCall.getMethod().getSourceDeclaration().getASourceOverriddenMethod*() instanceof
    JoiningCollectorMethod
select joiningCall, "Could instead use `String.join` to join elements of $@", collectionExpr,
  "this collection"
