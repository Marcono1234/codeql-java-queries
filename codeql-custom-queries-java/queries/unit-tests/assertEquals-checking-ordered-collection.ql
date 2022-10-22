/**
 * Finds usage of `assertEquals` where the 'expected' argument is an ordered collection type
 * such as `LinkedHashSet`. The default collection `equals` implementations do not check for
 * the exact collection type and do not consider element order. Therefore using an ordered
 * collection type has the same effect as if an unordered collection type was used.
 * For example:
 * ```java
 * Set<String> actual = new LinkedHashSet<>(Arrays.asList("b", "c", "a"));
 * LinkedHashSet<String> expected = new LinkedHashSet<>(Arrays.asList("a", "b", "c"));
 * // Assertion passes; different element order is not detected
 * assertEquals(expected, actual);
 * ```
 * 
 * Instead, depending on the test framework, methods specific for checking the element order
 * have to be used. Alternatively `Set`s can to be converted to `List`s before they are
 * compared, and for `Map`s the entries can be stored in a `List` and can then be compared:
 * ```java
 * Set<E> actual = ...;
 * List<E> expected = ...;
 * assertEquals(expected, new ArrayList<>(actual));
 * 
 * Map<K, V> actual = ...;
 * List<Map.Entry<K, V>> expected = ...;
 * assertEquals(expected, new ArrayList<>(actual.entrySet()));
 * ```
 * 
 * @kind problem
 */

import java

import lib.AssertLib

from MethodAccess assertEqualsCall, AssertEqualsMethod assertEqualsMethod, RefType expectedArgType
where
    assertEqualsMethod = assertEqualsCall.getMethod()
    and expectedArgType = assertEqualsCall.getArgument(assertEqualsMethod.getFixedParamIndex()).getType().(RefType).getSourceDeclaration()
    and expectedArgType.getASourceSupertype*().hasQualifiedName("java.util", [
        "LinkedHashMap",
        "LinkedHashSet",
        "SortedMap",
        "SortedSet",
    ])
    // To reduce false positives only consider standard JDK collection types
    and expectedArgType.getPackage().hasName("java.util")
select assertEqualsCall, "Does not check if actual object has elements in same order"
