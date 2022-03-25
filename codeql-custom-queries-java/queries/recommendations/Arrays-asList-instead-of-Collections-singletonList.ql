/**
 * Finds calls to `Arrays.asList` with only the result of a single method call as argument.
 * To improve readability it might be better to prefer `Collections.singletonList` which makes
 * it obvious that the created list will only contain a single element.
 * 
 * Note that there is a slight difference, `Arrays.asList` creates a list which allows replacing
 * the element while `Collections.singletonList` creates a list which is completely unmodifiable.
 */

import java

class AsListMethod extends Method {
    AsListMethod() {
        getDeclaringType().hasQualifiedName("java.util", "Arrays")
        and hasName("asList")
    }
}

// Only consider MethodAccess as argument because then it is sometimes not clear whether
// the method might return an array; for fields or literals it is often obvious that the
// list will only contain a single element

from MethodAccess asListCall, MethodAccess argument
where
    asListCall.getMethod() instanceof AsListMethod
    and asListCall.getNumArgument() = 1
    and argument = asListCall.getArgument(0)
    // Ignore if array is provided as argument
    and not argument.getType().(Array).getComponentType() instanceof RefType
select asListCall, "Could be replaced with Collections.singletonList"
