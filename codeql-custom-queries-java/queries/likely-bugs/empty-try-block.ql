/**
 * Finds `try` statements with an empty block. Such statements might indicate a
 * mistake in the code since an empty block cannot throw any exceptions and therefore
 * a `try` statement does not make any sense.
 * 
 * This query also detects try-with-resources statements with an empty block which
 * only have a single resource expression. It would probably increase readability
 * to explicitly call the `close()` method of the resource instead.
 */

/*
 * TODO: Maybe in the future expand to detect expressions which cannot throw exceptions
 * as well, e.g. variable assignments; though need to check all child expressions,
 * maybe ideally create a CodeQL library for matching non-throwing expressions
 */

import java

predicate isEmpty(Stmt s) {
    s instanceof EmptyStmt
    or (
        s instanceof BlockStmt
        and forall(Stmt child | child = s.(BlockStmt).getAStmt() | isEmpty(child))
    )
}

from TryStmt tryStmt
where
    isEmpty(tryStmt.getBlock())
    // Ignore if there is a resource declaration; then `try` is used to create and
    // afterwards `close()` resource again
    and not exists(tryStmt.getAResourceDecl())
    // Ignore if there is at most one resource expression; should use `close()` instead
    // However for more than one code might benefit from `try-with-resources` closing all
    // resources and handling exceptions, so don't report it
    and count(tryStmt.getAResourceExpr()) <= 1
select tryStmt, "Has empty block"
