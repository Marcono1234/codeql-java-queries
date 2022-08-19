/**
 * Finds non-thread-safe assignments to `static` fields. When the field is then later read by a
 * different thread, that thread might not see the updated value, or might see it in an
 * inconsistent state.
 * 
 * This query reports the path from a (probably) publicly accessible method to the unsafe
 * assignment.
 * 
 * @kind path-problem
 */

import java

query predicate edges(ControlFlowNode a, ControlFlowNode b) {
    (
        a.getASuccessor() = b
        or exists(Call call, Callable callee | callee = call.getCallee() |
            call = a
            and call.getCallee().getBody().getBasicBlock().getFirstNode() = b
            and not callee.isSynchronized()
            // Only report the shortest call chain; ignore if callee itself is entry method
            and not isEntryMethod(callee)
        )
    )
    // And there is no synchronizing action
    and not exists(MethodAccess synchronizedCall |
        synchronizedCall = [a, b]
        and (
            synchronizedCall.getMethod().isSynchronized()
            or synchronizedCall.getMethod().getSourceDeclaration().getASourceOverriddenMethod*().hasQualifiedName("java.util.concurrent.locks", "Lock", "lock")
        )
    )
    and not exists(SynchronizedStmt synchronizedStmt |
        synchronizedStmt = [a, b]
    )
}

predicate isPubliclyVisible(RefType type) {
    type.isPublic()
    or (
        type.isProtected()
        and isPubliclyVisible(type.getEnclosingType())
    )
}

predicate isEntryMethod(Method m) {
    isPubliclyVisible(m.getDeclaringType())
    and (m.isProtected() or m.isPublic())
    // TODO: Check that module descriptor (in case it exists) exports package

    and not m.getDeclaringType() instanceof TestClass
}

from Field staticField, FieldWrite fieldWrite, Method entryMethod, ControlFlowNode entryNode, ControlFlowNode exitNode
where
    staticField.isStatic()
    and not staticField.isVolatile()
    and fieldWrite.getField() = staticField
    // For FieldWrite (or LValue) have to get node for RHS, see https://github.com/github/codeql/issues/5652
    and exitNode = fieldWrite.(FieldWrite).getRhs()
    and not fieldWrite.getRhs() = staticField.getInitializer()
    and isEntryMethod(entryMethod)
    and entryNode = entryMethod.getBody().getBasicBlock().getFirstNode()
    and not entryMethod.isSynchronized()
    and edges+(entryNode, exitNode)
select exitNode, entryNode, exitNode, "Non-thread-safe assignment to static field $@", staticField, staticField.getName()
