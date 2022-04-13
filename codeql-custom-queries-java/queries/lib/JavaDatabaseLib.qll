import java

/**
 * Holds if the source code in the database has most likely been compiled with Java 11 or newer.
 * Might have incorrect result when a project consists of multiple modules and only some of
 * the modules have been compiled with Java 11 or newer.
 */
predicate isJava11OrNewer() {
    // Method Collection.toArray(IntFunction) was added in Java 11
    // TODO: Verify that this does not hold when newer JDK was used, but Java < 11 was set as target / release version
    exists(Method m |
        m.getDeclaringType().hasQualifiedName("java.util", "Collection")
        and m.hasStringSignature("toArray(IntFunction<T[]>)")
    )
}
