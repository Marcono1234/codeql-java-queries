/**
 * Finds field reads which happen before any assignment to that field.
 */

// TODO: Merge with likely-bugs/reading-uninitialized-field.ql

import java

predicate doesConstructorInitialize(Constructor c, Field f) {
    exists (FieldWrite fieldWrite |
        fieldWrite.getEnclosingCallable() = c
        and fieldWrite.getField() = f
    )
    or exists (ThisConstructorInvocationStmt delegateCall |
        delegateCall.getEnclosingCallable() = c
        and doesConstructorInitialize(delegateCall.getCallee(), f)
    )
}

predicate occursExprBefore(Expr before, Expr after) {
    exists (ExprParent commonParent, Expr beforeChild, Expr afterChild |
        beforeChild = before.getParent*()
        and beforeChild.getParent() = commonParent
        and afterChild = after.getParent*()
        and afterChild.getParent() = commonParent
        and beforeChild.getIndex() < afterChild.getIndex()
    )
    or exists (StmtParent commonParent, Stmt beforeChild, Stmt afterChild |
        beforeChild = before.getEnclosingStmt().getParent*()
        and beforeChild.getParent() = commonParent
        and afterChild = after.getEnclosingStmt().getParent*()
        and afterChild.getParent() = commonParent
        and beforeChild.getIndex() < afterChild.getIndex()
    )
}

Expr getFieldWritingExpr(Field f, Callable enclosing) {
    result.getEnclosingCallable() = enclosing
    and (
        result.(FieldWrite).getField() = f
        // Expr is method call which writes field
        /*
         * This permits some false positives in case method calls (transitively)
         * another method which initializes field, though in that case maybe call
         * hierarchy should be refactored to return that value as result instead
         * and then perform field assignment with returned value in constructor
         */
        or exists (FieldWrite fieldWrite |
            fieldWrite.getField() = f
            and fieldWrite.getEnclosingCallable() = result.(MethodAccess).getMethod()
        )
    )
}

/**
 * Assign expr which increments variable regardless of previous
 * value.
 */
class CumulatingAssignExpr extends Expr {
    CumulatingAssignExpr() {
        this instanceof AssignAddExpr
        or this instanceof AssignOrExpr
        or this instanceof PreIncExpr
        or this instanceof PostIncExpr
    }
    
    RValue getDest() {
        result = this.(AssignOp).getDest()
        or result = this.(UnaryAssignExpr).getExpr()
    }
}

from FieldRead fieldRead, Field f, Constructor enclosingConstructor
where
    f = fieldRead.getField()
    and not f.isStatic()
    and enclosingConstructor = fieldRead.getEnclosingCallable()
    // Make sure that field read belongs to constructed type
    and f.getDeclaringType() = enclosingConstructor.getDeclaringType()
    and fieldRead.isOwnFieldAccess()
    // Make sure no other constructor is called which initializes field
    and not exists (ThisConstructorInvocationStmt delegateCall |
        delegateCall.getEnclosingCallable() = enclosingConstructor
        and doesConstructorInitialize(delegateCall.getCallee(), f)
    )
    and not exists (Expr fieldWritingExpr |
        fieldWritingExpr = getFieldWritingExpr(f, enclosingConstructor)
        and occursExprBefore(fieldWritingExpr, fieldRead)
    )
    and (
        // Constructor performs assignment (checked in previous steps
        // that this happens after read)
        exists (getFieldWritingExpr(f, enclosingConstructor))
        // Or has field has no initializer (otherwise field read is safe)
        // Case where field has initializer and assignment is unsafe because
        // initialized value would be overwritten
        or not exists (f.getInitializer())
    )
    // Make sure that field read does not happen as part of assign expr
    // which increments field in loop (e.g. as counter)
    and not exists (LoopStmt loopStmt, CumulatingAssignExpr assignExpr |
        loopStmt.getEnclosingCallable() = enclosingConstructor
        and fieldRead.getEnclosingStmt().getEnclosingStmt*() = loopStmt
        and assignExpr.getDest() = fieldRead
    )
    // Make sure that field is not used as counter in for loop
    // (there read in condition happens before write in update)
    and not exists (ForStmt forStmt, FieldWrite fieldWrite |
        forStmt.getEnclosingCallable() = enclosingConstructor
        and fieldRead.getParent*() = forStmt.getCondition()
        and fieldWrite.getField() = f
        and fieldWrite.getParent*() = forStmt.getAnUpdate()
    )
    // Make sure that field is not lazily initialized in loop, e.g. field read
    // if null check and then initializes it
    and not exists (LoopStmt loopStmt, IfStmt ifStmt, FieldWrite fieldWrite |
        loopStmt.getEnclosingCallable() = enclosingConstructor
        and ifStmt.getEnclosingStmt+() = loopStmt
        and fieldRead.getParent+() = ifStmt.getCondition()
        and fieldWrite.getField() = f
        and fieldWrite.getEnclosingStmt().getEnclosingStmt*() = ifStmt.getThen()
    )
select fieldRead
