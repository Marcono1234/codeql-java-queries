/**
 * Finds fields which are assigned and afterwards a callable is called which uses
 * the field. Such fields could be removed and instead a parameter for this value
 * could be added to the callable. This can improve the readability of the code
 * by making the usage of the value clearer.
 * 
 * For example:
 * ```java
 * public class Queue {
 *     private int size;
 *     private Object[] table;
 * 
 *     public Queue(int size) {
 *         // size is only used by setUp()
 *         this.size = size;
 *         setUp();
 *     }
 * 
 *     private void setUp() {
 *         table = new Object[size];
 *         ...
 *     }
 * }
 * ```
 * Should be changed by adding a parameter to the method:
 * ```java
 * public class Queue {
 *     private Object[] table;
 * 
 *     public Queue(int size) {
 *         // Good: size is passed as argument
 *         setUp(size);
 *     }
 * 
 *     private void setUp(int size) {
 *         table = new Object[size];
 *         ...
 *     }
 * }
 * ```
 */

import java

predicate isPrivateOrPackagePrivate(Modifiable m) {
    m.isPrivate()
    or not (
        m.isProtected()
        or m.isPublic()
    )
}

predicate isStaticOrOwnFieldAccess(FieldAccess f) {
    f.getField().isStatic()
    or f.isOwnFieldAccess()
}

predicate isStaticOrOwnCall(Call c) {
    exists(Callable callee | callee = c.getCallee() |
        (callee instanceof Method) implies (
            callee.isStatic()
            or c.(MethodAccess).isOwnMethodAccess()
        )
    )
}

class FieldAssign extends FieldWrite {
    AssignExpr assignExpr;

    FieldAssign() {
        assignExpr.getDest() = this
    }

    // FieldWrite (or LValue in general) is variable access, which has no control flow
    // see https://github.com/github/codeql/issues/5652; therefore get node of assignment
    ControlFlowNode getAssignControlFlowNode() {
        result = assignExpr.getControlFlowNode()
    }
}

FieldAssign getPrecededingFieldAssign(Call call, Field f) {
    result.getField() = f
    and isStaticOrOwnFieldAccess(result)
    and result.getAssignControlFlowNode().getASuccessor+() = call
}

FieldAssign getDominatingFieldAssign(FieldRead fieldRead) {
    result.getField() = fieldRead.getField()
    and isStaticOrOwnFieldAccess(result)
    and result.getEnclosingCallable() = fieldRead.getEnclosingCallable()
    and dominates(result.getAssignControlFlowNode(), fieldRead)
}

// Report one FieldRead - FieldAssign pair where a parameter could be used (there might be multiple)
from Field f, FieldRead reportedFieldRead, FieldAssign reportedFieldAssign, Callable readEnclosingCallable
where
    f.fromSource()
    // Only consider private and package private fields to be sure no external class can access it
    and isPrivateOrPackagePrivate(f)
    and reportedFieldRead.getField() = f
    // Note: The logic here mirrors the checks in the `forex` loop below
    and isStaticOrOwnFieldAccess(reportedFieldRead)
    and reportedFieldRead.getEnclosingCallable() = readEnclosingCallable
    and isPrivateOrPackagePrivate(readEnclosingCallable)
    and reportedFieldAssign = getPrecededingFieldAssign(readEnclosingCallable.getAReference(), f)
    // Ignore field assignments in initializers; it can improve readability to store a constant in a
    // field by giving the field an expressive name
    and not reportedFieldAssign.getEnclosingCallable() instanceof InitializerMethod
    // Every field assign has to happen on own field (or field is static)
    and forall(FieldAssign fieldAssign |
        fieldAssign.getField() = f
    |
        isStaticOrOwnFieldAccess(fieldAssign)
    )
    // Make sure that all field usage allows replacing field with parameter
    and forex(FieldRead fieldRead |
        fieldRead.getField() = f
    |
        isStaticOrOwnFieldAccess(fieldRead)
        and (
            // Field is only used locally
            exists(getDominatingFieldAssign(fieldRead))
            // Or field could be replaced with local variable whose value is passed as call argument
            or exists(Callable enclosingCallable |
                enclosingCallable = fieldRead.getEnclosingCallable()
                // Only consider private and package callables to be sure no external class can access it
                and isPrivateOrPackagePrivate(enclosingCallable)
            |
                forex(Call call |
                    call = enclosingCallable.getAReference()
                |
                    isStaticOrOwnCall(call)
                    and exists(getPrecededingFieldAssign(call, f))
                )
            )
        )
    )
    // Make sure there is no 'trailing' field assign (mirrors the logic of the `forex` loop above)
    // Otherwise field might store state and be used as toggle, e.g. boolean flag which is set to
    // `false` after an action was performed
    and forall(FieldAssign fieldAssign |
        fieldAssign.getField() = f
    |
        fieldAssign = getDominatingFieldAssign(_)
        or exists(FieldRead fieldRead, Callable fieldReadingCallable |
            fieldRead = f.getAnAccess()
            and fieldReadingCallable = fieldRead.getEnclosingCallable()
            and fieldAssign = getPrecededingFieldAssign(fieldReadingCallable.getAReference(), f)
        )
    )
select f, "Could be turned into a parameter of $@ callable, because it is assigned $@ and then used $@",
    readEnclosingCallable, "this", reportedFieldAssign, "here", reportedFieldRead, "here"
