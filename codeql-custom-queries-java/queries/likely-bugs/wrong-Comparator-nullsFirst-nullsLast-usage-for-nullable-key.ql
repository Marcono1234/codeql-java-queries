/**
 * Finds incorrect usage of the `Comparator` factory methods `nullsFirst` and `nullsLast` where the
 * desired behavior is apparently to handle nullable 'sort keys'.
 *
 * For example, consider this class:
 * ```java
 * class MyClass {
 *     public Integer getI() {
 *         return 2;
 *     }
 *
 *     public String getNullableS() {
 *         return null;
 *     }
 * }
 * ```
 *
 * An incorrect usage of `nullsFirst` might look like this:
 * ```java
 * Comparator<MyClass> comp = Comparator.comparing(MyClass::getI)
 *     .thenComparing(Comparator.nullsFirst(Comparator.comparing(MyClass::getNullableS)));
 * ```
 *
 * The problem is that `nullsFirst` here applies to the compared `MyClass`, not the nullable `String`.
 * So this will cause a `NullPointerException`.
 *
 * Instead one of the factory methods with separate 'sort key extractor' should be used, for example:
 * ```java
 * Comparator<MyClass> comp = Comparator.comparing(MyClass::getI)
 *     // First extracts the 'sort key', and then applies `nullsFirst` on it
 *     .thenComparing(MyClass::getNullableS, Comparator.nullsFirst(Comparator.naturalOrder()));
 * ```
 *
 * @id TODO
 * @kind problem
 */

import java

class ComparatorMethod extends Method {
  ComparatorMethod() {
    getSourceDeclaration().getDeclaringType().hasQualifiedName("java.util", "Comparator")
  }
}

from MethodAccess nullsHandlingCall, ComparatorMethod nullsHandlingMethod
where
  // Check for cases where `nullsFirst` / `nullsLast` is part of a comparator chain, and therefore the
  // intention was likely to handle null for a 'key' and not the object itself (otherwise the complete
  // chain would have been wrapped with `nulls...`)
  (
    // `comp.thenComparing(nulls)`
    exists(MethodAccess thenComparingCall |
      thenComparingCall.getMethod().(ComparatorMethod).getSignature() =
        "thenComparing(java.util.Comparator)" and
      thenComparingCall.getArgument(0) = nullsHandlingCall
    )
    or
    // `nulls.thenComparing(...)`
    exists(MethodAccess thenComparingCall |
      thenComparingCall.getMethod().(ComparatorMethod).getName().matches("thenComparing%") and
      thenComparingCall.getQualifier() = nullsHandlingCall
    )
  ) and
  nullsHandlingMethod = nullsHandlingCall.getMethod() and
  nullsHandlingMethod.hasName(["nullsFirst", "nullsLast"])
select nullsHandlingCall, "Potential incorrect usage of `" + nullsHandlingMethod.getName() + "`"
