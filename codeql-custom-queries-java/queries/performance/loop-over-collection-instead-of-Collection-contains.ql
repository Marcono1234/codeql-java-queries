/**
 * Finds enhanced `for` loops iterating over the elements of a `Collection` only
 * to check if any of the elements is equal to another object. E.g.:
 * ```java
 * public boolean isValidExtension(String extension) {
 *     for (String validExtension : EXTENSIONS) {
 *         if (validExtension.equals(extension)) {
 *             return true;
 *         }
 *     }
 *     return false;
 * }
 * ```
 * 
 * Instead of writing such loops, `Collection.contains(...)` can be used. Depending
 * on the type of the collection this might also be faster, e.g. for `HashSet`.
 */

import java
import semmle.code.java.controlflow.Guards
import lib.Loops

class EqualsCall extends MethodAccess {
    EqualsCall() {
        getMethod() instanceof EqualsMethod
    }

    Expr getAComparedExpr() {
        result = getQualifier()
        or result = getArgument(0)
    }

    predicate isBreakConditionFor(LoopStmt loop) {
        exists(Guard guard, Stmt exitingStmt |
            guard = this
            and exitingStmt = getAnExitingStatement(loop)
        |
            guard.controls(exitingStmt.getBasicBlock(), true)
        )
    }
}

class CountingExpression extends Expr {
    CountingExpression() {
        this instanceof UnaryAssignExpr
        or this instanceof AssignAddExpr
        or this instanceof AssignSubExpr
    }
}

from EnhancedForStmt forStmt, Variable forVar, Variable otherVar, EqualsCall equalsCall, RValue equalsCallForVarRead
where
    forVar = forStmt.getVariable().getVariable()
    // Iterable is a Collection
    and forStmt.getExpr().getType().(RefType).getASourceSupertype*().hasQualifiedName("java.util", "Collection")
    and equalsCall.getAnEnclosingStmt() = forStmt.getStmt()
    and equalsCall.getAComparedExpr() = equalsCallForVarRead
    and equalsCallForVarRead = forVar.getAnAccess()
    and equalsCall.getAComparedExpr() = otherVar.getAnAccess()
    // Equals call is condition for loop break
    and equalsCall.isBreakConditionFor(forStmt)
    and forVar != otherVar
    // And neither element variable nor other variable are modified in loop
    and not exists(LValue varWrite |
        varWrite.getVariable() = forVar
        or varWrite.getVariable() = otherVar
    |
        varWrite.getAnEnclosingStmt() = forStmt.getStmt()
    )
    // And there exists no other read of element variable
    and not exists(RValue otherForVarRead |
        otherForVarRead = forVar.getAnAccess()
        and otherForVarRead != equalsCallForVarRead
    )
    // And loop does not appear to be counting, e.g. to determine index
    and not any(CountingExpression e).getAnEnclosingStmt() = forStmt.getStmt()
select forStmt, "Only compares iterated elements $@; could replace loop with `Collection.contains(...)` call", equalsCall, "here"
