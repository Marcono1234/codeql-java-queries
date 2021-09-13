/**
 * Finds usage of JUnit 4's `@RunWith` annotation on a class extending JUnit 3's
 * `TestCase`. The `@RunWith` annotation overwrites the runner JUnit would
 * normally use, in this case the JUnit 3 runner. Therefore JUnit 3 setup, teardown
 * and test methods might not be executed anymore.
 */

import java
import lib.JUnit4

from JUnit38TestClass testClass, Annotation runWithAnnotation
where
    testClass.getAnAnnotation() = runWithAnnotation
    and runWithAnnotation.getType() instanceof JUnit4RunWithAnnotationType
select runWithAnnotation, "RunWith annotation on class extending JUnit 3 `TestCase`"
