/**
 * Finds methods which override another method and only throw an exception
 * but are not annotated with `@Deprecated`.
 * These methods are likely not supported and it would help the caller if
 * the compiler issued a warning on use of these methods (which will happen
 * if they are marked as deprecated).
 * However, if it is expected that a subclass might implement the behavior
 * of the method, then it should not be marked as deprecated.
 */

import java

predicate isOnlyStatement(Stmt stmt) {
    not exists (Stmt other |
        other != stmt
        and other.getParent() = stmt.getEnclosingCallable().getBody()
    )
}

class ThrowingMethod extends Method {
    ThrowingMethod() {
        exists (ThrowStmt throwStmt |
            throwStmt.getParent() = getBody()
            and isOnlyStatement(throwStmt)
        )
    }
}

class ThrowingOrDelegatingMethod extends Method {
    ThrowingOrDelegatingMethod() {
        this instanceof ThrowingMethod
        or exists (ThrowingMethod overridden, SuperMethodAccess superCall |
            this.overrides(overridden)
            and superCall.getMethod() = overridden
            and isOnlyStatement(superCall.getParent().(ExprStmt))
        )
    }
}

from ThrowingMethod m
where
    // Ignore classes inside test classes
    not m.getDeclaringType().getEnclosingType+() instanceof TestClass
    // Method overrides other method
    and exists (m.getAnOverride())
    and not exists (m.getAnAnnotation().(DeprecatedAnnotation))
    // Method is not overridden or overriding method is ThrowingOrDelegatingMethod
    and not exists (Method overriding |
        not overriding instanceof ThrowingOrDelegatingMethod
        and overriding.overrides(m)
    )
select m
