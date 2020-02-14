/**
 * Finds classes which implement interfaces containing only constants.
 * This exposes these constants in the public API of the class, cluttering it and potentially exposing 
 * implementation details. Instead static imports can be used for the constants.
 * 
 * See also https://stackoverflow.com/q/2659593
 */

import java

predicate hasOnlyConstants(Interface i) {
    not exists (Method m | m.getDeclaringType() = i and not m.isStatic())
  	and exists (Field f | f.getDeclaringType() = i and f.isStatic())
  	and forall (RefType s | i.getASupertype() = s | s.hasQualifiedName("java.lang", "Object") or hasOnlyConstants(s))
}

from Class c, Interface i
where
    c.getASupertype() = i
    and hasOnlyConstants(i)
select c, i
