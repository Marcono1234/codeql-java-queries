import java

/**
 * A comparison method which can be implemented, this includes methods such as `Comparable.compareTo`
 * and `Comparator.compare`.
 */
class ImplementableComparisonMethod extends Method {
    ImplementableComparisonMethod() {
        getDeclaringType().hasQualifiedName("java.lang", "Comparable") and hasName("compareTo")
        or getDeclaringType().hasQualifiedName("java.util", "Comparator") and hasName("compare")
        or getDeclaringType().hasQualifiedName("java.text", "Collator") and hasName("compare")
    }
}

/**
 * A method which compares two values and returns an `int` representing the comparison result.
 */
class ComparisonMethod extends Method {
    ComparisonMethod() {
        getSourceDeclaration().getASourceOverriddenMethod+() instanceof ImplementableComparisonMethod
        // Or a static comparison method
        or exists(RefType declaringType |
            declaringType = getDeclaringType()
        |
            declaringType instanceof BoxedType and hasName(["compare", "compareUnsigned"])
            or declaringType.hasQualifiedName("java.lang", "CharSequence") and hasName("compare")
            or declaringType.hasQualifiedName("java.util", "Arrays") and hasName(["compare", "compareUnsigned"])
            or declaringType.hasQualifiedName("java.util", "Objects") and hasName("compare")
        )
    }

    /**
     * Holds if this comparison method specifies exact return values (e.g. -1, 0 and 1) instead
     * of only defining the sign of the result.
     */
    predicate definesSpecificReturnValues() {
        getDeclaringType().getASourceSupertype*().hasQualifiedName("java.math", ["BigDecimal", "BigInteger"])
    }
}
