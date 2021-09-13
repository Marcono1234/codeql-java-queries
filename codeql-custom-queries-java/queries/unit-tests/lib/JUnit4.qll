import java
import Tests

abstract class JUnit4AnnotationType extends AnnotationType {
}

/**
 * Annotation type for test related methods, including setup and teardown methods.
 */
abstract class JUnit4TestMethodAnnotationType extends JUnit4AnnotationType {
}

class JUnit4TestAnnotationType extends JUnit4TestMethodAnnotationType {
    JUnit4TestAnnotationType() {
        hasQualifiedName("org.junit", "Test")
    }
}

class JUnit4TestAnnotation extends Annotation {
    JUnit4TestAnnotation() {
        getType() instanceof JUnit4TestAnnotationType
    }

    /** Gets the expected exception, if any. */
    TypeLiteral getExpectedException() {
        result = getValue("expected")
    }
}

class JUnit4IgnoreAnnotation extends JUnit4TestMethodAnnotationType {
    JUnit4IgnoreAnnotation() {
        hasQualifiedName("org.junit", "Ignore")
    }
}

class JUnit4InstanceRuleAnnotation extends JUnit4AnnotationType {
    JUnit4InstanceRuleAnnotation() {
        hasQualifiedName("org.junit", "Rule")
    }
}

class JUnit4ClassRuleAnnotation extends JUnit4AnnotationType {
    JUnit4ClassRuleAnnotation() {
        hasQualifiedName("org.junit", "ClassRule")
    }
}

class JUnit4FixMethodOrderAnnotation extends JUnit4AnnotationType {
    JUnit4FixMethodOrderAnnotation() {
        hasQualifiedName("org.junit", "FixMethodOrder")
    }
}

class JUnit4BeforeAnnotationType extends SetupAnnotationType, JUnit4TestMethodAnnotationType {
    JUnit4BeforeAnnotationType() {
        hasQualifiedName("org.junit", "Before")
    }
}

class JUnit4BeforeClassAnnotationType extends SetupAnnotationType, JUnit4TestMethodAnnotationType {
    JUnit4BeforeClassAnnotationType() {
        hasQualifiedName("org.junit", "BeforeClass")
    }
}

class JUnit4AfterAnnotationType extends TeardownAnnotationType, JUnit4TestMethodAnnotationType {
    JUnit4AfterAnnotationType() {
        hasQualifiedName("org.junit", "After")
    }
}

class JUnit4AfterClassAnnotationType extends TeardownAnnotationType, JUnit4TestMethodAnnotationType {
    JUnit4AfterClassAnnotationType() {
        hasQualifiedName("org.junit", "AfterClass")
    }
}

class JUnit4RunWithAnnotationType extends JUnit4AnnotationType {
    JUnit4RunWithAnnotationType() {
        hasQualifiedName("org.junit.runner", "RunWith")
    }
}
