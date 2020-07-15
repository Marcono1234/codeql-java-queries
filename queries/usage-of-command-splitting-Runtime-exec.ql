/**
 * Finds usage of the `java.lang.Runtime` `exec` methods which take a command
 * as `String` and then split it.
 * As stated in the documentation of these methods they simply use a `StringTokenizer`
 * which splits at ` \t\n\r\f`. It therefore does not parse the command and is
 * susceptible to command injection.
 * Most of the times the caller already knows the number of arguments and should
 * therefore use the `exec` overloads (or `ProcessBuilder`) which take the
 * command arguments separately. Since they do not need to split the command, they
 * likely perform better as well.
 */

import java

class CommandSplittingMethod extends Method {
    CommandSplittingMethod() {
        getDeclaringType() instanceof TypeRuntime
        and hasName("exec")
        and getParameterType(0) instanceof TypeString
    }
}

from MethodAccess call
where
    call.getMethod() instanceof CommandSplittingMethod
select call
