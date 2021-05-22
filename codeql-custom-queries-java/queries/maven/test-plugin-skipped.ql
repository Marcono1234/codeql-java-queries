/**
 * Finds test plugins (e.g. Maven Surefire and Failsafe plugin) which are
 * configured to skip execution. Not running unit tests on build will prevent
 * detecting bugs in the code.
 * 
 * If the intention was to make the build succeed despite some failing tests,
 * it might be better to exclude or disable these specific tests only.
 */

import lib.MavenLib

from TestPluginConfigElement testPluginConfigElement
select testPluginConfigElement.getASkippingElement(), "Skips execution of tests"
