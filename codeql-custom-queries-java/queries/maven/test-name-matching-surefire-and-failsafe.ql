/**
 * Finds test classes whose name matches the default patterns of both the Maven
 * Surefire and Failsafe plugin. Because the class name matches both patterns,
 * it might be redundantly executed twice, once as unit test and a second
 * time as integration test.
 *
 * @kind problem
 */

import java

// TODO: If necessary, could maybe improve accuracy by making sure Failsafe is actually configured as plugin in `pom.xml`

from TopLevelClass c, string name, string prefix, string suffix
where
    name = c.getName()
    and name.matches(prefix + "%" + suffix)
    // https://maven.apache.org/surefire/maven-surefire-plugin/test-mojo.html#includes
    // https://maven.apache.org/surefire/maven-failsafe-plugin/integration-test-mojo.html#includes
    and (
        // Surefire prefix, Failsafe suffix
        prefix = ["Test"] and suffix = ["IT", "ITCase"]
        or
        // Failsafe prefix, Surefire suffix
        prefix = ["IT"] and suffix = ["Test", "Tests", "TestCase"]
    )
    // Ignore if prefix or suffix might be part of abbreviation (mostly relevant for "IT")
    // For example "ITFBlackBox1TestCase" in zxing repository
    and not(
        prefix.isUppercase()
        and exists (int tooManyUpperLettersCount |
            // Should at most expect + 1 to match Java naming conventions, e.g. "ITHighTraffic"
            tooManyUpperLettersCount = prefix.length() + 2
        |
            name.regexpMatch("\\p{Upper}{" + tooManyUpperLettersCount.toString() + ",}.*")
        )
        or
        suffix.isUppercase()
        and exists (int tooManyUpperLettersCount |
            // There should not be any leading uppercase letter to match Java naming conventions, e.g. "HighTrafficIT"
            tooManyUpperLettersCount = suffix.length() + 1
        |
            name.regexpMatch(".*\\p{Upper}{" + tooManyUpperLettersCount.toString() + ",}")
        )
    )
select c, "Name of this class matches default Surefire and Failsafe pattern"
