/**
 * Finds classes which implement `java.lang.CharSequence`, but do not
 * override `toString()` as required by the method contract.
 */

import java

class TypeCharSequence extends Interface {
    TypeCharSequence() {
        hasQualifiedName("java.lang", "CharSequence") 
    }
}

predicate implementsACharSequenceMethod(Class c) {
    c.getAMethod().getAnOverride().getDeclaringType() instanceof TypeCharSequence
}

from Class c
where
    c.getASupertype() instanceof TypeCharSequence
    // Make sure class implements at least one method and does keep
    // all of them abstract
    and implementsACharSequenceMethod(c)
    // Class does not override toString()
    and not c.getAMethod().hasStringSignature("toString()")
select c
