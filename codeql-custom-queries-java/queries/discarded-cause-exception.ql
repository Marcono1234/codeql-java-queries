/**
 * Finds `catch` blocks which throw a new exception without setting the caught 
 * exception as cause (either through the constructor call or through `initCause`), 
 * effectively discarding the stack trace of the cause.
 */

import java

predicate encloses(Stmt s, Stmt enclosing) {
    s.getEnclosingStmt() = enclosing
    or encloses(s.getEnclosingStmt(), enclosing)
}

/*
 * Could be improved:
 *  - Verify that caught exception (and not any other) is set as cause
 *  - Verify that cause is set for thrown exception (and not any other)
 */
predicate containsSetCause(Stmt s) {
    exists (MethodAccess call, Method m | call.getMethod() = m |
        m.getSignature() = "initCause(java.lang.Throwable)"
        and m.getDeclaringType() instanceof ThrowableType
        and encloses(call.getEnclosingStmt(), s)
      )
      or exists (ClassInstanceExpr new, Constructor c | new.getConstructor() = c |
        new.getConstructedType() instanceof ThrowableType
        and exists (| c.getAParamType() instanceof ThrowableType)
        and encloses(new.getEnclosingStmt(), s)
    )
}

predicate createsNewException(Stmt s) {
    exists (ClassInstanceExpr new |
        new.getConstructedType() instanceof ThrowableType
        and encloses(new.getEnclosingStmt(), s)
    )
}

from CatchClause catch, ThrowStmt throw
where
    encloses(throw, catch)
    and createsNewException(catch)
    and not containsSetCause(catch)
select catch, throw
