/**
 * Finds calls to `Arrays.asList()` with an empty array. Because the list
 * returned by that method has a fixed size, using an empty array effectively
 * creates an empty unmodifiable list.
 * It is recommended to use `Collections.emptyList()` instead which makes
 * this intention more obvious.
 */

import java

class AsListMethod extends Method {
    AsListMethod() {
        getDeclaringType().hasQualifiedName("java.util", "Arrays")
        and hasName("asList")
    }
}

from MethodAccess asListCall
where
    asListCall.getMethod() instanceof AsListMethod
    and (
        // No arguments
        asListCall.getNumArgument() = 0
        // Or empty array
        or exists(Argument arg | arg = asListCall.getArgument(0) |
            // Not an implicit varargs array element
            arg.isExplicitVarargsArray()
            and arg.(ArrayCreationExpr).getFirstDimensionSize() = 0
        )
    )
select asListCall, "Calls Arrays.asList() with empty array"
