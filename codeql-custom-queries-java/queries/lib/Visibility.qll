import java

private newtype TVisibility =
    TPrivate()
    or TPackagePrivate()
    or TProtected(ClassOrInterface declaringType) {
        // Restrict this here already to all possible values to avoid too large result sets
        // when visibilities are compared
        exists(Member m |
            m.isProtected()
            and m.getDeclaringType() = declaringType
        )
    }
    or TPublic()

/**
 * Visibility of a type or member, either implicit or specified through a modifier.
 * 
 * Comparing visibilities directly (e.g. `vis1 = vis2`) is discouraged because two
 * members with `protected` visibility but different declaring type will not have
 * the same visibility. Instead `hasSameRank(Visibility)` should be used.
 */
abstract class Visibility extends TVisibility {
    /**
     * Gets the rank of this visibility, the higher the more visible it is.
     */
    abstract int getVisibilityRank();

    /**
     * Holds if this and the other visibility have the same rank, e.g.
     * both are `public`.
     */
    predicate hasSameRank(Visibility other) {
        getVisibilityRank() = other.getVisibilityRank()
    }

    /**
     * Holds if this visibility is `protected` or a higher visibility.
     */
    predicate isProtectedOrHigher() {
        getVisibilityRank() >= 2
    }

    /**
     * Holds if this visibility can 'see' the other visibility, i.e.
     * the other one is at least as high.
     */
    predicate canSee(Visibility other) {
        other.getVisibilityRank() >= getVisibilityRank()
    }

    /**
     * Gets the visibility which is lower, either `this` or `other`.
     */
    Visibility getLower(Visibility other) {
        // Other has lower visibility
        if other.canSee(this) then result = other
        // Will also have `this` as result when neither can see each other, e.g.
        // when both are `protected` but with different declaring type
        else result = this
    }

    /**
     * Gets a string describing this visibility.
     */
    abstract string toString();
}

/**
 * Element is `private`.
 */
class PrivateVisibility extends Visibility, TPrivate {
    override
    int getVisibilityRank() {
        result = 0
    }

    override
    string toString() {
        result = "private"
    }
}

/**
 * Element is package-private.
 */
class PackagePrivateVisibility extends Visibility, TPackagePrivate {
    override
    int getVisibilityRank() {
        result = 1
    }

    override
    string toString() {
        result = "package-private"
    }
}

/**
 * Element is `protected`.
 */
class ProtectedVisibility extends Visibility, TProtected {
    ClassOrInterface declaringType;

    ProtectedVisibility() {
        this = TProtected(declaringType)
    }

    override
    int getVisibilityRank() {
        // When changing this value, `isProtectedOrHigher()` must be adjusted as well
        result = 2
    }

    override
    predicate canSee(Visibility other) {
        // Other has strictly greater visibility
        other.getVisibilityRank() > getVisibilityRank()
        // Or both are `protected` and this visibility is same or subtype of other
        // Checking declaring types is necessary because `other` could for example
        // only be declared in same top level type or in a non-directly enclosing type;
        // subclassing `this` would then not make `other` visible
        or getDeclaringType().getASourceSupertype*() = other.(ProtectedVisibility).getDeclaringType()
    }

    /**
     * Gets the type which declares this element, i.e. the enclosing type.
     */
    ClassOrInterface getDeclaringType() {
        result = declaringType
    }

    override
    string toString() {
        result = "protected (declared by " + getDeclaringType().getName() + ")"
    }
}

/**
 * Element is `public`.
 */
class PublicVisibility extends Visibility, TPublic {
    override
    int getVisibilityRank() {
        result = 3
    }

    override
    string toString() {
        result = "public"
    }
}

/**
 * Gets the visibility of the type.
 */
Visibility getVisibility(RefType t) {
    if t.isPrivate() then result instanceof PrivateVisibility
    else if t.isProtected() then result.(ProtectedVisibility).getDeclaringType() = t.getEnclosingType().getSourceDeclaration()
    else if t.isPublic() then result instanceof PublicVisibility
    else result instanceof PackagePrivateVisibility
}

/**
 * Gets the effective visibility of `t` by getting the lowest visibility
 * of itself and all of its enclosing types, if any.
 */
Visibility getEffectiveVisibility(RefType t) {
    exists(Visibility v | v = getVisibility(t) |
        // Get result fast, without checking enclosing, if visibility is private (lowest visibility)
        if v instanceof PrivateVisibility or t.isTopLevel() then result = v
        else exists(RefType enclosing, Visibility enclosingV |
            enclosing = t.getEnclosingType()
            and enclosingV = getEffectiveVisibility(enclosing)
        |
            result = v.getLower(enclosingV)
        )
    )
}

/**
 * Gets the visibility of the member.
 */
Visibility getMemberVisibility(Member m) {
    if m.isPrivate() then result instanceof PrivateVisibility
    else if m.isProtected() then result.(ProtectedVisibility).getDeclaringType() = m.getDeclaringType().getSourceDeclaration()
    else if m.isPublic() then result instanceof PublicVisibility
    else result instanceof PackagePrivateVisibility
}
