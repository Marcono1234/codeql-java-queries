/**
 * Finds test plugins (e.g. Maven Surefire and Failsafe plugin) which are
 * configured to ignore the test results. This will prevent detecting
 * bugs in the code.
 * 
 * If the intention was to make the build succeed despite some failing tests,
 * it might be better to exclude or disable these specific tests only.
 */

import lib.MavenLib

from TestPluginConfigElement testPluginConfigElement
select testPluginConfigElement.getAResultIgnoringElement(), "Ignores test results"
