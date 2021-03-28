/**
 * Finds classes or interfaces which appear to be 'complex' (e.g. define multiple `protected`
 * or `public` methods or fields) but implement one of the standard `java.util.function`
 * functional interfaces. These interfaces are rather nondescriptive, they are mostly intended
 * as parameter types for simple actions. It should therefore be avoided to have a complex
 * class implement them. Instead when the complex class should be used where a functional
 * interface is expected, a _method reference expression_ or _lambda expression_ should be used.
 * E.g.:
 * ```java
 * // BAD: Should not extend Predicate
 * interface List<E> extends Predicate<Object> {
 *     void add(E e);
 *     E get(int index);
 *     int size();
 *     boolean contains(Object o);
 * 
 *     // BAD: Method `test` is pretty nondescriptive for List
 *     @Override
 *     default boolean test(Object o) {
 *         return contains(o);
 *     }
 * }
 * ```
 * Instead a method reference expression should be used where a `Predicate` is expected:
 * ```java
 * List<String> allowedStrings = ...;
 * strings.stream()
 *     // GOOD: Uses method reference expression where Predicate is expected
 *     .filter(allowedStrings::contains)
 *     .forEach(...);
 * ```
 */

import java

pragma[inline] // Inlining this seems to improve performance
private int nonStaticMethodsCount(RefType t, Interface functionalInterface) {
    result = count(Method m |
        // Only consider publicly visible methods
        (m.isPublic() or m.isProtected())
        // Ignore static methods, they are likely unrelated to complexity of type
        and not m.isStatic()
        // Consider all directly declared methods or inherited ones
        and t.inherits(m)
        // Ignore Object and Enum methods and methods inherited from functional interface
        and not exists(Method ignoredMethod, RefType declaringType |
            declaringType = ignoredMethod.getDeclaringType()
            and (
                declaringType instanceof TypeObject
                or declaringType = functionalInterface
                or declaringType.hasQualifiedName("java.lang", "Enum")
            )
        |
            m.getSourceDeclaration().overridesOrInstantiates*(ignoredMethod)
        )
    )
}

pragma[inline] // Inlining this seems to improve performance
private int nonStaticFieldsCount(RefType t) {
    result = count(Field f |
        // Only consider publicly visible fields
        (f.isPublic() or f.isProtected())
        // Ignore static fields, they are likely unrelated to complexity of type
        and not f.isStatic()
        // Consider all directly declared fields or inherited ones
        and t.inherits(f)
    )
}

pragma[inline] // Inlining this seems to improve performance
predicate isComplexType(RefType t, Interface functionalInterface) {
    (
        t instanceof Class
        and nonStaticMethodsCount(t, functionalInterface) + nonStaticFieldsCount(t) >= 4
    )
    or (
        t instanceof Interface
        // Interface can only have static fields, therefore only consider methods
        and nonStaticMethodsCount(t, functionalInterface) >= 2
    )
}

class StandardFunctionalInterface extends Interface {
    StandardFunctionalInterface() {
        getPackage().hasName("java.util.function")
    }
}

// Only consider standard functional interfaces because they are nondescriptive
// Don't consider custom functional interfaces
from RefType complexType, StandardFunctionalInterface functionalInterface
where
    complexType.fromSource()
    and complexType.getASupertype().getSourceDeclaration() = functionalInterface
    /*
     * For generic types raw type is a supertype; so for OpenJDK types such as BinaryOperator
     * which are themselves standard functional interfaces have to make sure that the types
     * are different, otherwise methods inherited from Function interface would not be ignored
     * and BinaryOperator would be erroneously reported as complex type
     */
    and complexType != functionalInterface
    /*
     * Note: This only ignores methods inherited from functionalInterface but considers
     * methods from other implemented standard functional interfaces. This behavior is
     * probably good because implementing multiple standard functional interfaces might
     * indicate a complex type as well
     */
    and isComplexType(complexType, functionalInterface)
    // Ignore test classes (or classes whose enclosing type is a test class)
    and not complexType instanceof TestClass
select complexType, "Complex type implements standard functional interface " + functionalInterface.getName()
