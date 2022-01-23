/**
 * Finds usage of `java.lang.ref.PhantomReference.get()`.
 * As described by the documentation of the method, it will always return `null`.
 * The `PhantomReference` class is intended for clean-up actions where it is only
 * relevant to know when an object has been garbage collected. Use stronger references
 * such as `WeakReference` if you want to access the object when it has not been
 * garbage collected yet.
 */

import java
import lib.Expressions

class PhantomReferenceType extends Class {
    PhantomReferenceType() {
        hasQualifiedName("java.lang.ref", "PhantomReference")
    }
}

class PhantomReferenceGetMethod extends Method {
    PhantomReferenceGetMethod() {
        getDeclaringType().getASourceSupertype*() instanceof PhantomReferenceType
        and hasStringSignature("get()")
    }
}

class PhantomRefGetExpr extends Expr {
    PhantomRefGetExpr() {
        this.(CallableReferencingExpr).getReferencedCallable() instanceof PhantomReferenceGetMethod
    }
}

from PhantomRefGetExpr phantomRefGet
select phantomRefGet
