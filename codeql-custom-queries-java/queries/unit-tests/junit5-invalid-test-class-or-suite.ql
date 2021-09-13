/**
 * Finds classes which appear to be intended as JUnit 5 test classes or test suite classes
 * but which do not meet the requirements for being a test class or test suite class.
 * Such classes will be silently ignored, causing test failures to go unnoticed.
 * 
 * See also related JUnit issue [242](https://github.com/junit-team/junit5/issues/242)
 * and SonarSource rules [RSPEC-5790](https://rules.sonarsource.com/java/tag/junit/RSPEC-5790)
 * and [RSPEC-5810](https://rules.sonarsource.com/java/tag/junit/RSPEC-5810).
 */

import java
import lib.JUnit5

// https://github.com/junit-team/junit5/blob/ed3d84d0db3807ae4065221c47d10448ea60e74b/junit-jupiter-engine/src/main/java/org/junit/jupiter/engine/discovery/predicates/IsTestClassWithTests.java
predicate couldBeTestClass(ClassOrInterface c) {
    exists(Method m |
        m = getAMethod(c)
        and exists(AnnotationType testMethodAnnotationType |
            testMethodAnnotationType instanceof JUnit5TestCaseAnnotationType
            or testMethodAnnotationType instanceof JUnit5TestFactoryAnnotationType
        |
            hasAnnotationOfType(m, testMethodAnnotationType)
        )
    )
    or hasAnnotationOfType(getANestedType(c), any(JUnit5NestedAnnotationType n))
}

from ClassOrInterface c, string message, string reason
where
    c.fromSource()
    and (
        (
            couldBeTestClass(c) and message = "Test class is not valid"
            // Invalid classes annotated with @Nested is covered by a separate query
            and not hasAnnotationOfType(c, any(JUnit5NestedAnnotationType n))
            // Ignore if there is a subtype, then it might act as test class
            and not any(RefType t).getASourceSupertype+() = c
        )
        or hasAnnotationOfType(c, any(JUnit5SuiteAnnotationType s)) and message = "Test suite is not valid"
    )
    and (
        c.isPrivate() and reason = "Must not be private"
        or c.isAbstract() and reason = "Must not be abstract"
        or c instanceof InnerClass and reason = "Must not be inner class"
    )
select c, message + ": " + reason
