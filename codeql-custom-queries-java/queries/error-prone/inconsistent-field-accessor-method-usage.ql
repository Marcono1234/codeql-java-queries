/**
 * Finds direct fields reads or field assignments in a class in which other field access to that field
 * occurs through the corresponding getter or setter method, and where a subclass could override
 * the getter or setter method. This can lead to inconsistent behavior when a subclass overrides the
 * getter or setter method, for example to perform additional validation or to transform the value.
 * For example:
 * ```java
 * public class MutableNumber {
 *     private int value;
 * 
 *     public void set(int value) {
 *         this.value = value;
 *     }
 * 
 *     public void add(int amount) {
 *         set(value + amount);
 *     }
 * 
 *     public void subtract(int amount) {
 *         // Problematic; if a subclass overrides `set(int)` to implement additional
 *         // requirements (e.g. >= 0), then this method here would not adhere to
 *         // these requirements
 *         value -= amount;
 *     }
 * }
 * ```
 * 
 * @kind problem
 */

import java
import lib.Types

from Field f, RefType declaringType, FieldAccess access, MethodAccess accessMethodCall, Method accessMethod, string message
where
    access.getField() = f
    and declaringType = f.getDeclaringType()
    // Field access occurs in declaring type
    and access.getEnclosingCallable().getDeclaringType() = declaringType
    and accessMethod = accessMethodCall.getMethod()
    and accessMethod.getDeclaringType() = declaringType
    // And accessor method can be overridden by subclass, e.g. to implement additional requirement
    and accessMethod.isOverridable()
    // Only consider if protected or public; ignore if package-private
    and (accessMethod.isProtected() or accessMethod.isPublic())
    and accessMethodCall.isOwnMethodAccess()
    // And method access occurs in declaring type
    and accessMethodCall.getEnclosingCallable().getDeclaringType() = declaringType
    // And type can be subclassed (otherwise method cannot be overridden)
    and isPubliclySubclassable(declaringType)
    and (
        access instanceof FieldRead
        and accessMethod.(GetterMethod).getField() = f
        and message = "Directly accesses field, but $@ the getter method is used"
        or
        access instanceof FieldWrite
        and accessMethod.(SetterMethod).getField() = f
        and message = "Directly accesses field, but $@ the setter method is used"
    )
    // Ignore the direct access in the access method itself
    and not access.getEnclosingCallable() = accessMethod
    // Ignore direct access in the constructor, e.g. for initialization
    and not access.getEnclosingCallable().(Constructor).getDeclaringType() = declaringType
select access, message, accessMethodCall, "here"
