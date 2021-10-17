/**
 * Finds `java.util.Iterator` implementations whose `next()` method only returns
 * values of primitive types. To avoid boxing of these values one of the specialized
 * primitive type iterators, such as `PrimitiveIterator.OfInt`, should be implemented
 * instead.
 */

import java

class TypeIterator extends Interface {
    TypeIterator() {
        hasQualifiedName("java.util", "Iterator")
    }
}

class IteratorNextMethod extends Method {
    IteratorNextMethod() {
        exists(Method overridden |
            overridden = getSourceDeclaration().getASourceOverriddenMethod*()
            and overridden.getDeclaringType() instanceof TypeIterator
            and overridden.hasStringSignature("next()")
        )
    }
}

class NumericPrimitiveType extends PrimitiveType {
    NumericPrimitiveType() {
        not hasName("boolean")
    }
}

from IteratorNextMethod nextMethod
where
    nextMethod.fromSource()
    and forex(ReturnStmt returnStmt |
        returnStmt.getEnclosingCallable() = nextMethod
    |
        // Note: Ignore `boolean` because there exists no good primitive iterator alternative for it
        returnStmt.getResult().getType() instanceof NumericPrimitiveType
    )
    // Only consider direct Iterator implementation, otherwise might not be possible to switch
    and nextMethod.getDeclaringType().getASourceSupertype() instanceof TypeIterator
select nextMethod, "Only returns values of primitive type; should implement primitive type Iterator instead"
