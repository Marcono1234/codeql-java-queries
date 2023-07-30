/**
 * Finds redundant usage of `Stream.sorted()` where a subsequent collection step does
 * not preserve order, for example `collect(Collectors.toSet())`.
 * 
 * Either remove the redundant `sorted()` call or use a `Collectors` factory method which
 * preserves the element order, for example by providing a `Set` factory which creates
 * a `LinkedHashSet`.
 * 
 * This query might produce false positives when intermediate stream steps have side-effects,
 * and the sorting is needed for these intermediate steps. However, note that side-effects in
 * intermediate steps are generally discouraged, see the
 * [documentation](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/stream/package-summary.html#SideEffects).
 * 
 * This query is based on IntelliJ IDEA's 'RedundantStreamOptionalCall' warning.
 * 
 * @kind problem
 */

import java

class StreamType extends RefType {
    StreamType() {
        getSourceDeclaration().getASourceSupertype*().hasQualifiedName("java.util.stream", [
            "Stream",
            "DoubleStream",
            "IntStream",
            "LongStream",
        ])
    }
}

class SortedMethod extends Method {
    SortedMethod() {
        getDeclaringType() instanceof StreamType
        and hasName("sorted")
    }
}

class CollectMethod extends Method {
    CollectMethod() {
        getDeclaringType() instanceof StreamType
        and hasName("collect")
    }
}

class PotentiallyOrderIgnoringCollectorsMethod extends Method {
    PotentiallyOrderIgnoringCollectorsMethod() {
        getDeclaringType().hasQualifiedName("java.util.stream", "Collectors")
        // Only consider methods which always or depending on the arguments might ignore the order;
        // ignore methods which always preserve order such as `groupingBy` (because it returns `Map<..., List<...>>`)
        and hasName([
            "toCollection",
            "toConcurrentMap",
            "toMap",
            "toSet",
            "toUnmodifiableMap",
            "toUnmodifiableSet",
        ])
    }
}

/**
 * `Collectors` method which always ignores order, regardless of provided arguments (if any).
 */
class OrderIgnoringCollectorsMethod extends PotentiallyOrderIgnoringCollectorsMethod {
    OrderIgnoringCollectorsMethod() {
        // Ignore overload with `mapFactory` parameter
        hasName(["toConcurrentMap", "toMap"]) and getNumberOfParameters() <= 3
        or
        hasName(["toSet", "toUnmodifiableMap", "toUnmodifiableSet"])
    }
}

/**
 * Intermediate stream method which depends on the order of elements, without violating best
 * practices, e.g. taking a stateful filter predicate.
 */
class OrderDependentMethod extends Method {
    OrderDependentMethod() {
        getDeclaringType() instanceof StreamType
        and hasName([
            "limit",
            "skip",
        ])
    }
}

class UnorderedCollectionType extends RefType {
    UnorderedCollectionType() {
        hasQualifiedName("java.util", [
            // In theory the actual instance could already be LinkedHashSet or LinkedHashMap, which preserve the order,
            // but assume that this is unlikely if type is already explicitly HashSet or HashMap instead of Set or Map
            "HashSet", "HashMap",
        ])
        or hasQualifiedName("java.util.concurrent", ["ConcurrentMap", "ConcurrentHashMap"])
    }
}

from MethodAccess sortedCall, MethodAccess collectCall, MethodAccess collectorsCall
where
    sortedCall.getMethod() instanceof SortedMethod
    and collectCall.getMethod() instanceof CollectMethod
    and collectCall.getQualifier+() = sortedCall
    and collectCall.getArgument(0) = collectorsCall
    and collectorsCall.getMethod() instanceof PotentiallyOrderIgnoringCollectorsMethod
    // And seems to collect into collection type which does not preserve order
    and (
        collectorsCall.getMethod() instanceof OrderIgnoringCollectorsMethod
        // Or other relevant Collectors method for which user provided arguments to create
        // an unordered collection; don't check supertype here because that would erroneously
        // match LinkedHashSet and LinkedHashMap then whose supertypes are HashSet and HashMap
        or collectCall.getType().(RefType).getSourceDeclaration() instanceof UnorderedCollectionType
    )
    // And there is no order dependent call in between which justifies usage of `sorted`
    and not exists(MethodAccess orderDependentCall |
        orderDependentCall.getMethod() instanceof OrderDependentMethod
        and orderDependentCall.getQualifier+() = sortedCall
        and collectCall.getQualifier+() = orderDependentCall
    )
    // And all chained calls return a Stream; this excludes cases where for example in between
    // the elements are collected to a List and a new Stream is created
    and forall(MethodAccess chainedCall |
        chainedCall.getQualifier+() = sortedCall
        and collectCall.getQualifier+() = chainedCall
    |
        chainedCall.getType() instanceof StreamType
    )
select sortedCall, "Sorting has no effect because $@ elements are collected without preserving order", collectorsCall, "here"
