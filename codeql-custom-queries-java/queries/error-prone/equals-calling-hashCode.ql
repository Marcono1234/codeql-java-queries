/**
 * Finds `equals(Object)` methods which call `hashCode()`. Such calls are error-prone
 * because `hashCode()` returns a 32-bit `int` so the number of different results it
 * can have is limited. It can therefore happen that two objects which are not equal
 * have the same hash code.
 * 
 * Additionally `hashCode()` might be less efficient because unlike `equals(Object)`
 * it cannot return fast. For example for a collection class it might have to consider
 * the hash code of all elements whereas `equals(Object)` could return fast once the
 * first unequal element is found.
 */

import java

from EqualsMethod equalsMethod, MethodAccess hashCodeCall
where
    equalsMethod = hashCodeCall.getEnclosingCallable()
    and hashCodeCall.getMethod() instanceof HashCodeMethod
select hashCodeCall, "hashCode() call within equals(Object) method"
