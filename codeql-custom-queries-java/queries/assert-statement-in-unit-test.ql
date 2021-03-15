/**
 * Finds usage of the Java `assert` statement within unit tests.
 * Unit test frameworks normally offer functionality to perform assertions,
 * e.g. for JUnit 5 the class `org.junit.jupiter.api.Assertions` offers static
 * methods to perform assertions. These methods should be preferred since they
 * are guaranteed to run (Java assertions can be disabled at runtime), often
 * produce more meaningful error messages in case the assertion fails and also
 * have special support by the IDEs.
 */

import java

from AssertStmt assertStmt
where
    assertStmt.getEnclosingCallable().getDeclaringType().getEnclosingType*() instanceof TestClass
select assertStmt
