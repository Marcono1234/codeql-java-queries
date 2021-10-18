import java
import Tests

abstract class TestNgAnnotationType extends AnnotationType {
}

/**
 * Annotation type for test related methods, including setup and teardown methods.
 */
abstract class TestNgTestMethodAnnotationType extends TestNgAnnotationType {
}

class TestNgBeforeSuiteAnnotationType extends SetupAnnotationType, TestNgTestMethodAnnotationType {
    TestNgBeforeSuiteAnnotationType() {
        hasQualifiedName("org.testng.annotations", "BeforeSuite")
    }
}

class TestNgAfterSuiteAnnotationType extends TeardownAnnotationType, TestNgTestMethodAnnotationType {
    TestNgAfterSuiteAnnotationType() {
        hasQualifiedName("org.testng.annotations", "AfterSuite")
    }
}

class TestNgBeforeTestAnnotationType extends SetupAnnotationType, TestNgTestMethodAnnotationType {
    TestNgBeforeTestAnnotationType() {
        hasQualifiedName("org.testng.annotations", "BeforeTest")
    }
}

class TestNgAfterTestAnnotationType extends TeardownAnnotationType, TestNgTestMethodAnnotationType {
    TestNgAfterTestAnnotationType() {
        hasQualifiedName("org.testng.annotations", "AfterTest")
    }
}

class TestNgBeforeGroupsAnnotationType extends SetupAnnotationType, TestNgTestMethodAnnotationType {
    TestNgBeforeGroupsAnnotationType() {
        hasQualifiedName("org.testng.annotations", "BeforeGroups")
    }
}

class TestNgAfterGroupsAnnotationType extends TeardownAnnotationType, TestNgTestMethodAnnotationType {
    TestNgAfterGroupsAnnotationType() {
        hasQualifiedName("org.testng.annotations", "AfterGroups")
    }
}

class TestNgBeforeClassAnnotationType extends SetupAnnotationType, TestNgTestMethodAnnotationType {
    TestNgBeforeClassAnnotationType() {
        hasQualifiedName("org.testng.annotations", "BeforeClass")
    }
}

class TestNgAfterClassAnnotationType extends TeardownAnnotationType, TestNgTestMethodAnnotationType {
    TestNgAfterClassAnnotationType() {
        hasQualifiedName("org.testng.annotations", "AfterClass")
    }
}

class TestNgBeforeMethodAnnotationType extends SetupAnnotationType, TestNgTestMethodAnnotationType {
    TestNgBeforeMethodAnnotationType() {
        hasQualifiedName("org.testng.annotations", "BeforeMethod")
    }
}

class TestNgAfterMethodAnnotationType extends TeardownAnnotationType, TestNgTestMethodAnnotationType {
    TestNgAfterMethodAnnotationType() {
        hasQualifiedName("org.testng.annotations", "AfterMethod")
    }
}

class TestNgTestAnnotationType extends TestNgTestMethodAnnotationType {
    TestNgTestAnnotationType() {
        hasQualifiedName("org.testng.annotations", "Test")
    }
}

class TestNgSoftAssert extends Class {
    TestNgSoftAssert() {
        hasQualifiedName("org.testng.asserts", "SoftAssert")
    }
}
