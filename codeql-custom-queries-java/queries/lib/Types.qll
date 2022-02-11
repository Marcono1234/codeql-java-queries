import java

// Note: Cannot use RefType.getASubtype() because it apparently does not work when supertype
// is parameterized, e.g. IntList extends List<Integer>
private RefType getASubtypeOrSelf(RefType t) {
    result.getASourceSupertype*() = t
}

/**
 * Holds if the type is a sealed type (Java 17 feature).
 */
predicate isSealedType(ClassOrInterface t) {
    permits(t, any(ClassOrInterface subType))
}

/**
 * Holds if the type is accessible from a different package at compile time and
 * can be subclassed.
 */
predicate isPubliclySubclassable(RefType t) {
    // TODO: Also consider whether module declaration (if any) exports package
    (
        t instanceof Interface
        or exists(Constructor c |
            c.getDeclaringType() = t
            and (c.isProtected() or c.isPublic())
        )
    )
    and (
        t.isTopLevel()
        and t.isPublic()
        or
        (t.isProtected() or t.isPublic())
        // Also consider subtypes here in case they make the nested type accessible
        and isPubliclySubclassable(getASubtypeOrSelf(t.getEnclosingType()))
    )
    and not t.isFinal()
    and not isSealedType(t)
    or
    isPubliclySubclassable(getASubtypeOrSelf(t))
}
