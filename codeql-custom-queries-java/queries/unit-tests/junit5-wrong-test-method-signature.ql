/**
 * Finds JUnit 5 test methods which do not match the expected method signature. Such
 * test methods will be silently ignored, causing test failures to go unnoticed.
 * 
 * See [JUnit 5 issue 242](https://github.com/junit-team/junit5/issues/242) and
 * [SonarSource rule RSPEC-5810](https://rules.sonarsource.com/java/tag/junit/RSPEC-5810).
 */

import java
import lib.JUnit5

// See https://github.com/junit-team/junit5/blob/ed3d84d0db3807ae4065221c47d10448ea60e74b/junit-jupiter-engine/src/main/java/org/junit/jupiter/engine/discovery/predicates/IsTestableMethod.java
class TestableAnnotationType extends AnnotationType {
    boolean voidReturnType;
    
    TestableAnnotationType() {
        voidReturnType = true and this instanceof JUnit5TestCaseAnnotationType
        or voidReturnType = false and this instanceof JUnit5TestFactoryAnnotationType
    }

    boolean requiresVoidReturnType() {
        result = voidReturnType
    }
}

class AnnotatedTestMethod extends Method {
    TestableAnnotationType annotationType;

    AnnotatedTestMethod() {
        hasAnnotationOfType(this, annotationType)
    }

    string getInvalidTestMethodReason() {
        isStatic() and result = "Must not be static"
        or isPrivate() and result = "Must not be private"
        or isAbstract() and result = "Must not be abstract"
        or exists(boolean hasVoid, boolean requiresVoid |
            if (getReturnType() instanceof VoidType) then hasVoid = true
            else hasVoid = false
            and requiresVoid = annotationType.requiresVoidReturnType()
            and (
                hasVoid = false and requiresVoid = true and result = "Requires void return type"
                or hasVoid = true and requiresVoid = false and result = "Requires non-void return type"
            )
        )
    }
}

from AnnotatedTestMethod testMethod, string reason
where
    testMethod.fromSource()
    and reason = testMethod.getInvalidTestMethodReason()
select "Invalid test method: " + reason
