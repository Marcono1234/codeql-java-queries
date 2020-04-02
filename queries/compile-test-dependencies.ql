/**
 * Finds `compile` dependencies on artifacts which are only used
 * for testing. Such dependencies should dependencies should have
 * the scope `test` (unless the project is a test project).
 */

import semmle.code.xml.MavenPom

class TestDependency extends PomDependency {
    TestDependency() {
        exists (string groupId | groupId = getGroup().getValue() |
            groupId = "junit" // JUnit 4
            or groupId = "org.junit.jupiter" // JUnit 5
            or groupId = "org.testng"
            or groupId = "org.assertj"
            or groupId = "com.google.truth"
            or groupId = "org.hamcrest"
            or groupId = "org.dbunit"
            or groupId = "org.spockframework"
            or groupId = "org.mockito"
            or groupId = "org.jmock"
            or groupId = "org.easymock"
            or groupId = "io.mockk"
            or groupId = "org.testcontainers"
            or groupId = "com.google.testing.compile"
        )
        or getShortCoordinate() = "com.google.guava:guava-testlib"
        or getShortCoordinate() = "com.ninja-squad:springmockk"
        or getShortCoordinate() = "org.springframework:spring-test"
    }
}

from TestDependency testDependency
where
    // TODO: Verify that dependencyManagement (of parent) does not provide scope
    testDependency.getScope() = "compile"
    and not testDependency.getAChild("optional").getTextValue() = "true"
select testDependency
