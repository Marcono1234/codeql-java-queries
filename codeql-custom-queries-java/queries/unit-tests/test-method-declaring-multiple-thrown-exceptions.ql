/**
 * Finds unit test methods which declare multiple thrown exception types as
 * part of their `throws` clause.
 * 
 * Since the method signature does not matter for test methods, it would be
 * better to simply declare `throws Exception` to increase readability.
 */

import java

from TestMethod testMethod, int exceptionsCount
where
    exceptionsCount = count(Exception exception |
        exception = testMethod.getAnException()
        // TODO Need to check fromSource() because thrown exception instances are reported
        // See https://github.com/github/codeql/issues/5464
        and exception.fromSource()
    )
    // 2 is still fairly well readable
    and exceptionsCount > 2
select testMethod, "Should declare `throws Exception` instead of declaring " + exceptionsCount + " thrown exceptions"
