/**
 * Finds resources declared by try-with-resources statements which are only used
 * conditionally, i.e. the resource might not be used at all depending on the
 * condition. Since resource creation is often expensive, the condition should
 * be moved outside the try-with-resources statement to only create the resource
 * if it will actually be used.
 * 
 * For example:
 * ```java
 * void processFile(Path path) throws IOException {
 *     try (InputStream in = Files.newInputStream(path)) {
 *         // Bad: Resource is not used at all if this evaluates to `false`
 *         if (path.getFileName().toString().endsWith(".txt")) {
 *             ...
 *         }
 *     }
 * }
 * ```
 * Instead the condition should be moved outside:
 * ```java
 * void processFile(Path path) throws IOException {
 *     // Good: Only creates resource if it will actually be used
 *     if (path.getFileName().toString().endsWith(".txt")) {
 *         try (InputStream in = Files.newInputStream(path)) {
 *             ...
 *         }
 *     }
 * }
 * ```
 * 
 * Note that in some cases resource creation has side effects which are desired
 * even if the resource is not used at all.
 */

import java
import semmle.code.java.controlflow.Guards

Guard getAccessGuard(TryStmt tryStmt, Variable resource) {
    // Guard is within try block; ignore when guard is around try statement
    result.getEnclosingStmt().getEnclosingStmt*() = tryStmt.getBlock()
    // `branch` value does not matter, only has to be the same for all accesses
    and exists(boolean branch | branch = [true, false] |
        // Every read access is controlled by guard (this also excludes variables
        // which are used by other resource declarations)
        forex(RValue resourceRead | resourceRead = resource.getAnAccess() |
            result.controls(resourceRead.getBasicBlock(), branch)
        )
    )
    // Ignore if guard is condition of loop, e.g. when copying bytes from
    // InputStream to OutputStream and loop keeps track of progress
    and not any(LoopStmt s).getCondition() = result.(Expr).getParent*()
    // Also ignore if there is any loop between try statement body and
    // guard, then the value checked by the guard might change in the loop
    and not exists(LoopStmt loop |
        loop.getEnclosingStmt+() = tryStmt.getBlock()
        // First `getEnclosingStmt()` is defined by Guard, cannot use transitive closure only for that
        and result.getEnclosingStmt*().getEnclosingStmt*() = loop.getBody()
    )
}

from TryStmt tryStmt, Variable resource, Guard accessGuard
where
    // Only consider declarations of resources (but not resource expressions)
    resource = tryStmt.getAResourceDecl().getAVariable().getVariable()
    and accessGuard = getAccessGuard(tryStmt, resource)
    // Only report the outermost guard
    and not exists(Guard otherGuard |
        otherGuard != accessGuard
        and otherGuard = getAccessGuard(tryStmt, resource)
        and strictlyDominates(otherGuard, accessGuard)
    )
select resource, "Resource is only conditionally used based on $@ guard", accessGuard, "this"
