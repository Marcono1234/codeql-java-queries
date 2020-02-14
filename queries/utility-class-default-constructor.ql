/**
 * Finds classes with default constructor which have only static fields or methods. 
 * These classes are likely utility classes and should therefore declare a private 
 * constructor to hide the implicit public default one.
 */

import java

predicate hasStaticFieldOrMethod(Class c) {
    exists(Method m | c.getAMethod() = m and m.getDeclaringType() = c and m.isStatic())
    or exists (Field f | c.getAField() = f and f.getDeclaringType() = c and f.isStatic())
}

predicate hasInstanceFieldOrMethod(Class c) {
    exists(Method m | c.getAMethod() = m and m.getDeclaringType() = c and not m.isStatic())
    or exists(Field f | c.getAField() = f and f.getDeclaringType() = c and not f.isStatic())
}

from Class c
where
    c.getASupertype().hasQualifiedName("java.lang", "Object")
    and not c.isAnonymous() // Anonymous types pretend to have no superclass
    and hasStaticFieldOrMethod(c)
    and not hasInstanceFieldOrMethod(c)
    and c.getAConstructor().isDefaultConstructor()
select c
