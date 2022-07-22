/**
 * Finds `throw` statements which throw an exception which is read from a field.
 * That exception might have been created by a completely unrelated caller, possibly
 * even from a different thread. Because the stack trace is captured where the exception
 * is created (and not where it is thrown), this means its stack trace is unrelated to
 * the current caller. This makes debugging difficult and confusing when this exception
 * is thrown. Instead a new exception should be created, if necessary with the existing
 * one as cause.
 * 
 * If the current implementation was chosen for performance reasons, it should be
 * verified that this really justifies the increased effort for debugging. Exceptions
 * should not be used for normal control flow and therefore they should only occur
 * in error situations.
 * 
 * @kind problem
 */

import java

from ThrowStmt throwStmt, Field f
where
    f = throwStmt.getExpr().(FieldRead).getField()
    // For now only consider static fields to reduce false positives
    and f.isStatic()
    and not throwStmt.getEnclosingCallable().getDeclaringType() instanceof TestClass
select throwStmt, "Throws exception which might have completely unrelated stack trace"
