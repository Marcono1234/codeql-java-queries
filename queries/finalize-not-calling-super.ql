/**
 * `finalize()` implementations should call the parent `finalize()`
 * implementation.
 */

import java

// CodeQL has FinalizeMethod, but that requires that method is protected
// even though subclass can also make it public
class Finalize extends Method {
    Finalize() {
        this.hasStringSignature("finalize()")
    }
}

from Finalize finalize
where
    // Check if no super call exists
    not exists (Finalize superFinalize | finalize.callsSuper(superFinalize))
    // Ignore types which have no explicit parent class (i.e. Object is their parent class)
    // `finalize()` guarantees that `Object.finalize()` does nothing
    and not exists(TypeObject object | finalize.getDeclaringType().hasSupertype(object))
select finalize
