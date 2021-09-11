/**
 * Finds test classes in Maven projects whose class name does not follow the naming
 * conventions of the Maven Failsafe Plugin or the Maven Surefire Plugin.
 * 
 * Unless custom class name patterns are specified, these test classes will not
 * be executed by Maven which can cause test failures to go unnoticed.
 * 
 * See also [SonarSource rule RSPEC-3577](https://rules.sonarsource.com/java/tag/tests/RSPEC-3577).
 */

import java
import semmle.code.xml.MavenPom

string getATestClassPrefix() {
    // https://maven.apache.org/surefire/maven-surefire-plugin/test-mojo.html#includes
    // https://maven.apache.org/surefire/maven-failsafe-plugin/integration-test-mojo.html#includes
    result = [
        "Test",
        "IT"
    ]
}

string getATestClassSuffix() {
    // https://maven.apache.org/surefire/maven-surefire-plugin/test-mojo.html#includes
    // https://maven.apache.org/surefire/maven-failsafe-plugin/integration-test-mojo.html#includes
    result = [
        "Test", "Tests", "TestCase",
        "IT", "ITCase"
    ]
}

from TopLevelType testClass, string className
where
    testClass instanceof TestClass
    and testClass.fromSource()
    and className = testClass.getName()
    // And make sure this is a Maven project
    and any(Pom p).getASourceRefType() = testClass
    and not exists(string prefixPattern, string suffixPattern |
        prefixPattern = "^(" + concat(getATestClassPrefix(), "|") + ").*"
        and suffixPattern = ".*(" + concat(getATestClassSuffix(), "|") + ")$"
        and className.regexpMatch([prefixPattern, suffixPattern])
    )
    // And no other test class uses field or method of test class;
    // then test class might only be a helper class
    and not exists(TestClass otherTestClass |
        otherTestClass.getEnclosingType*() != testClass
        and (
            exists(FieldAccess fieldAccess |
                fieldAccess.getField().getDeclaringType().getEnclosingType*() = testClass
                and fieldAccess.getEnclosingCallable().getDeclaringType() = otherTestClass
            )
            or exists(Call call |
                call.getCallee().getDeclaringType().getEnclosingType*() = testClass
                and call.getEnclosingCallable().getDeclaringType() = otherTestClass
            )
        )
    )
    // And no other test class extends the test class;
    // then test class might only be a helper class
    and not exists(ClassOrInterface testClassOrNested, ClassOrInterface extendingTestClass |
        testClassOrNested.getEnclosingType*() = testClass
        and testClassOrNested.fromSource()
        and extendingTestClass.fromSource()
        and extendingTestClass.getASourceSupertype+() = testClassOrNested
        and extendingTestClass.getEnclosingType+() != testClass
    )
select testClass, "Name of test class does not follow naming convention"
