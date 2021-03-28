/**
 * Finds non-`final` publicly visible classes which hide their constructors by making them
 * private or package-private, but which have `protected` static members.
 * 
 * If the `protected` members should not be accessible from untrusted code it is necessary
 * to reduce their visibility or make the declaring class `final`. Even though Java source
 * code cannot subclass a class with hidden constructors, custom Java classfiles allow
 * subclassing and accessing the static members. E.g.:
 * ```java
 * public class PubliclyVisibleClass {
 *     // Prevent creating instances
 *     private PubliclyVisibleClass() { }
 * 
 *     // BAD: Custom Java classfiles can subclass this class and access this static method
 *     protected static void performInternalAction() {
 *         ...
 *     }
 * }
 * ```
 * 
 * @kind problem
 */

 import java
 import lib.Visibility
 import lib.TopLevelVisibility

from Class c, Member protectedMember
where
    c.fromSource()
    // Class is publicly visible
    and getEffectiveVisibility(c).isProtectedOrHigher()
    and getTopLevelVisibility(c).isVisibleToOtherModules()
    // Ignore if class is final, then custom classfiles cannot subclass it
    and not c.isFinal()
    and protectedMember.getDeclaringType() = c
    // Only consider protected members; public ones can be accessed anyway
    and protectedMember.isProtected()
    and protectedMember.isStatic()
    // And all constructors are not publicly visible
    and not exists(Constructor constructor |
        (constructor.isPublic() or constructor.isProtected())
        and constructor.getDeclaringType() = c
    )
select c, "Custom Java classfiles can subclass this class and access protected member $@", protectedMember, protectedMember.getName()
