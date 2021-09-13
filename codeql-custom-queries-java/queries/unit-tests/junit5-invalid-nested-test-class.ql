/**
 * Finds classes annotated with JUnit 5's `@Nested` which do not meet the requirements
 * for being a nested test class. Such classes will be silently ignored, causing test
 * failures to go unnoticed.
 * 
 * See [JUnit 5 issue 242](https://github.com/junit-team/junit5/issues/242) and
 * SonarSource rules [RSPEC-5790](https://rules.sonarsource.com/java/tag/junit/RSPEC-5790)
 * and [RSPEC-5810](https://rules.sonarsource.com/java/tag/junit/RSPEC-5810).
 */

import java
import lib.JUnit5

// See https://github.com/junit-team/junit5/blob/ed3d84d0db3807ae4065221c47d10448ea60e74b/junit-jupiter-engine/src/main/java/org/junit/jupiter/engine/discovery/predicates/IsNestedTestClass.java

from ClassOrInterface c, string reason
where
    c.fromSource()
    and hasAnnotationOfType(c, any(JUnit5NestedAnnotationType n))
    and (
        c.isPrivate() and reason = "Must not be private"
        or not c instanceof MemberType and reason = "Must be a member class"
        or c.(MemberType).isStatic() and reason = "Must not be static"
        // Currently not checked by JUnit, see https://github.com/junit-team/junit5/issues/2717
        or c.isAbstract() and reason = "Must not be abstract"
    )
select c, "Not a valid nested test class: " + reason
