/**
 * Finds test plugins (e.g. Maven Surefire and Failsafe plugin) which are
 * configured to restrict which tests are executed.
 * 
 * Often unit test frameworks provide their own mechanisms to disable test
 * classes or methods, for example JUnit 5 has the `@Disabled` annotation.
 * These mechanisms can be used more fine-grained, e.g. to disable only
 * a specific method instead of the complete test class, and allow specifying
 * a reason why a test has been be disabled. Additionally they have better
 * IDE support so when running tests from the IDE these tests will be
 * skipped as well.
 */

import lib.MavenLib

from TestPluginConfigElement testPluginConfigElement
select testPluginConfigElement.getARestrictingElement(), "Restricts which tests are executed"
