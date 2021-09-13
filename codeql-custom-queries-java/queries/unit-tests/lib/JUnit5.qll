/**
 * Library for classes and predicates specific to JUnit 5.
 */

import java
import Tests

/**
 * JUnit 5 annotation indicating that the annotated element is "testable".
 */
class JUnit5TestableAnnotationType extends AnnotationType {
    JUnit5TestableAnnotationType() {
        hasQualifiedName("org.junit.platform.commons.annotation", "Testable")
    }
}

/**
 * Annotation type for test related methods, including setup and teardown methods.
 */
abstract class JUnit5TestMethodAnnotationType extends AnnotationType {
}

class JUnit5TestAnnotationType extends AnnotationType, JUnit5TestMethodAnnotationType {
    JUnit5TestAnnotationType() {
        hasQualifiedName("org.junit.jupiter.api", "Test")
    }
}

// Don't have this extend JUnit5TestMethodAnnotationType because it is not a test method on its own
class JUnit5TestFactoryAnnotationType extends AnnotationType {
    JUnit5TestFactoryAnnotationType() {
        hasQualifiedName("org.junit.jupiter.api", "TestFactory")
    }
}

class JUnit5TestTemplateAnnotationType extends AnnotationType, JUnit5TestMethodAnnotationType {
    JUnit5TestTemplateAnnotationType() {
        hasQualifiedName("org.junit.jupiter.api", "TestTemplate")
    }
}

class JUnit5NestedAnnotationType extends AnnotationType {
    JUnit5NestedAnnotationType() {
        hasQualifiedName("org.junit.jupiter.api", "Nested")
    }
}

class JUnit5SuiteAnnotationType extends AnnotationType {
    JUnit5SuiteAnnotationType() {
        hasQualifiedName("org.junit.platform.suite.api", "Suite")
    }
}

class JUnit5BeforeEachAnnotationType extends SetupAnnotationType, JUnit5TestMethodAnnotationType {
    JUnit5BeforeEachAnnotationType() {
        hasQualifiedName("org.junit.jupiter.api", "BeforeEach")
    }
}

class JUnit5BeforeAllAnnotationType extends SetupAnnotationType, JUnit5TestMethodAnnotationType {
    JUnit5BeforeAllAnnotationType() {
        hasQualifiedName("org.junit.jupiter.api", "BeforeAll")
    }
}

class JUnit5AfterEachAnnotationType extends TeardownAnnotationType, JUnit5TestMethodAnnotationType {
    JUnit5AfterEachAnnotationType() {
        hasQualifiedName("org.junit.jupiter.api", "AfterEach")
    }
}

class JUnit5AfterAllAnnotationType extends TeardownAnnotationType, JUnit5TestMethodAnnotationType {
    JUnit5AfterAllAnnotationType() {
        hasQualifiedName("org.junit.jupiter.api", "AfterAll")
    }
}

/**
 * An annotation type which either marks a test case or a template for test cases.
 */
class JUnit5TestCaseAnnotationType extends AnnotationType {
    JUnit5TestCaseAnnotationType() {
        this instanceof JUnit5TestAnnotationType
        or this instanceof JUnit5TestTemplateAnnotationType
    }
}

/**
 * Holds if the annotatable has an annotation of the specified type.
 * The check is performed the same way as
 * [implemented by JUnit 5](https://github.com/junit-team/junit5/blob/ed3d84d0db3807ae4065221c47d10448ea60e74b/junit-platform-commons/src/main/java/org/junit/platform/commons/util/AnnotationUtils.java#L140).
 */
predicate hasAnnotationOfType(Annotatable annotatable, AnnotationType type) {
    // Annotation directly present (or inherited)
    annotatable.getAnAnnotation().getType() = type
    // Or check meta annotations, i.e. the annotation type is annotated
    or hasAnnotationOfType(annotatable.getAnAnnotation().getType(), type)
    // Or super interface has annotation (this differs from normal Java annotation inheritance)
    or hasAnnotationOfType(annotatable.(ClassOrInterface).getASupertype().(Interface), type)
}

/**
 * Gets a nested type, including nested types of supertypes.
 * This is performed the same way as
 * [implemented by JUnit 5](https://github.com/junit-team/junit5/blob/ed3d84d0db3807ae4065221c47d10448ea60e74b/junit-platform-commons/src/main/java/org/junit/platform/commons/util/ReflectionUtils.java#L1041).
 */
MemberType getANestedType(ClassOrInterface enclosing) {
    result.getEnclosingType() = enclosing.getASourceSupertype*()
}

/**
 * Gets a method declared or inherited by the type.
 * This predicate roughly behaves the same way as
 * [implemented by JUnit 5](https://github.com/junit-team/junit5/blob/ed3d84d0db3807ae4065221c47d10448ea60e74b/junit-platform-commons/src/main/java/org/junit/platform/commons/util/ReflectionUtils.java#L1335).
 */
Method getAMethod(ClassOrInterface c) {
    (
        // For classes methods with any visibility are considered
        result = c.(Class).getASourceSupertype*().getAMethod()
        or (
            result.isPublic()
            and c.inherits(result)
        )
    )
    and not c instanceof TypeObject
}
