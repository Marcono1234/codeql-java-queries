/**
 * Finds a test class extending `junit.framework.TestCase`, which is present for
 * both JUnit 3 and 4, but which also uses annotations such as `@Test` added in
 * JUnit 4. When a class extends `TestCase` all JUnit 4 annotations will be ignored.
 */

import java
import lib.JUnit4

from JUnit38TestClass testClass, Annotation junit4Annotation
where
    testClass.getAMember().getAnAnnotation() = junit4Annotation
    and junit4Annotation.getType() instanceof JUnit4AnnotationType
select junit4Annotation, "Usage of JUnit 4 annotation in test class extending JUnit 3 `TestCase`"
