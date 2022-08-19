/**
 * Finds call paths to field reads before the field has been assigned. This could lead to
 * `NullPointerException`s or other incorrect behavior.
 * 
 * @kind path-problem
 */

// TODO: Make this more accuracte

import java

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

// Note: Uses ExprParent for `b` because that is the common superclass of Call and FieldRead
query predicate edges(Call a, ExprParent b) {
    // TODO: If possible exclude `new` instance creations if field is an instance field
    // (since that could case false positives)
    isStaticOrOwnCall(a)
    and (
        b.(Call).getEnclosingCallable() = a.getCallee()
        or b.(FieldRead).getEnclosingCallable() = a.getCallee()
    )
}

class InitializingCallable extends Callable {
    InitializingCallable() {
        this instanceof InitializerMethod
        or this instanceof Constructor
    }
}

Expr getAFieldAssigningExpr(Field f, Callable enclosingCallable) {
    result.getEnclosingCallable() = enclosingCallable
    and (
        (
            result.(FieldAssign).getField() = f
            and isStaticOrOwnFieldAccess(result)
        )
        // Consider nested call chains, but only within constructors or initializers
        or enclosingCallable instanceof InitializingCallable
        and exists(Call call, Callable callee |
            call = result
            and callee = call.getCallee()
            and callee.getDeclaringType().getSourceDeclaration() = enclosingCallable.getDeclaringType().getSourceDeclaration().getASourceSupertype*()
        |
            isStaticOrOwnCall(call)
            // Ignore call from static initializer to instance if field is instance field
            and (
                f.isStatic()
                or not enclosingCallable instanceof StaticInitializer
            )
            // And in case there are condition nodes, then for true and false branch there
            // has to be an assignment
            and forall(ConditionNode conditionNode |
                conditionNode.getEnclosingCallable() = callee
            |
                exists(Expr trueAssign |
                    trueAssign = conditionNode.getATrueSuccessor().getASuccessor*()
                    and trueAssign = getAFieldAssigningExpr(f, callee)
                )
                and exists(Expr falseAssign |
                    falseAssign = conditionNode.getAFalseSuccessor().getASuccessor*()
                    and falseAssign = getAFieldAssigningExpr(f, callee)
                )
            )
        )
    )
}

ControlFlowNode getAssignControlFlowNode(Expr e) {
    if e instanceof FieldAssign then result = e.(FieldAssign).getAssignControlFlowNode()
    else result = e.getControlFlowNode()
}

from InitializingCallable initializer, Field f, Expr fieldAssign, Call preAssignCall, Expr intermediateEdge, FieldRead preFieldRead
where
    fieldAssign = getAFieldAssigningExpr(f, initializer)
    and preAssignCall = getAssignControlFlowNode(fieldAssign).getAPredecessor+()
    // Ignore if field has already been assigned before read
    and not exists(Expr otherFieldAssign |
        otherFieldAssign = getAFieldAssigningExpr(f, initializer)
        and getAssignControlFlowNode(otherFieldAssign).getASuccessor+() = preAssignCall
    )
    and preFieldRead.getField() = f
    and isStaticOrOwnFieldAccess(preFieldRead)
    and edges+(preAssignCall, intermediateEdge)
    and intermediateEdge = preFieldRead
    // Ignore if field value is compile time constant; then field can be accessed before
    // initializer would be executed
    and not preFieldRead instanceof CompileTimeConstantExpr
select preFieldRead, preAssignCall, intermediateEdge, "Accesses field '" + f.getName() + "' before it is assigned $@", fieldAssign, "here"
