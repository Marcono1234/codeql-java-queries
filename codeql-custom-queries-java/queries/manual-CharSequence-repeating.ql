/**
 * Finds expressions which are manually creating a String consisting of
 * a `CharSequence` being repeated multiple times.
 * [`String.repeat(int)`](https://docs.oracle.com/en/java/javase/15/docs/api/java.base/java/lang/String.html#repeat(int)) (added in Java 11) should be used instead.
 */

import java
import semmle.code.java.dataflow.DataFlow

// TODO: Reduce code duplication; already declared in manual-CharSequence-joining.ql
class StringAppendingMethod extends Method {
    StringAppendingMethod() {
        (
            getDeclaringType() instanceof TypeStringBuilder
            or getDeclaringType() instanceof TypeStringBuffer
        )
        and hasName("append")
    }
}

private Expr getAStringRepeatingExpr(Expr charSequenceExpr) {
    // Only consider compile time constant or var read; other expressions
    // (such as method call) might have side effect
    (
      charSequenceExpr instanceof CompileTimeConstantExpr
      or charSequenceExpr instanceof VarAccess
    )
    and (
        // var = var + charSequenceExpr
        exists(Variable resultVar, AssignExpr assign, VarAccess resultVarRead, AddExpr concatExpr |
            resultVar.getType() instanceof TypeString
            and result = assign
            and assign.getDest() = resultVar.getAnAccess()
            and resultVarRead = resultVar.getAnAccess()
            and concatExpr = assign.getRhs()
        |
            concatExpr.getAnOperand() = resultVarRead
            and concatExpr.getAnOperand() = charSequenceExpr
            and resultVarRead != charSequenceExpr
        )
        // var += charSequenceExpr
        or exists(AssignAddExpr concatAddExpr |
            concatAddExpr = result
            and concatAddExpr.getDest().getType() instanceof TypeString
            and concatAddExpr.getRhs() = charSequenceExpr
        )
        // sb.append(charSequenceExpr)
        or exists(MethodAccess appendCall | result = appendCall |
            appendCall.getMethod() instanceof StringAppendingMethod
            and appendCall.getAnArgument() = charSequenceExpr
            // Only consider call on variable, but ignore if call is end of chained method calls
            and appendCall.getQualifier() instanceof VarAccess
            // Ignore if call is part of a call chain (and therefore not only creating simple
            // repeated CharSequence)
            and not exists(MethodAccess chainedCall |
                chainedCall.getQualifier() = appendCall
            )
        )
    )
}

class TypeCollections extends Class {
    TypeCollections() {
        hasQualifiedName("java.util", "Collections")
    }
}

class CollectionsNCopiesMethod extends Method {
    CollectionsNCopiesMethod() {
        getDeclaringType() instanceof TypeCollections
        and hasName("nCopies")
    }
}

class StringJoinMethod extends Method {
    StringJoinMethod() {
        getDeclaringType() instanceof TypeString
        and hasName("join")
    }
}

class TypeIterable extends Interface {
    TypeIterable() {
        hasQualifiedName("java.lang", "Iterable")
    }
}

private class IterableNoDelimiterJoiningCall extends MethodAccess {
    IterableNoDelimiterJoiningCall() {
        getMethod() instanceof StringJoinMethod
        // No delimiter
        and getArgument(0).(CompileTimeConstantExpr).getStringValue() = ""
        and getArgument(1).getType().(RefType).getASourceSupertype*() instanceof TypeIterable
    }
    
    Expr getJoinedArgument() {
        result = getArgument(1)
    }
}

class TypeCharSequence extends Interface {
    TypeCharSequence() {
        hasQualifiedName("java.lang", "CharSequence")
    }
}

from Expr repeatingExpr, Expr charSequenceExpr
where
    charSequenceExpr.getType().(RefType).getASourceSupertype*() instanceof TypeCharSequence
    // `for` statement repeating String by iterating over int variable
    and (
        exists(ForStmt forStmt, Stmt forBody |
            forBody = forStmt.getStmt()
            // Iterates over int variable
            and forStmt.getAnIterationVariable().getType().hasName("int")
            and count(forStmt.getAnIterationVariable()) = 1
        |
            (
                // `for` statement without block directly containing ExprStmt
                repeatingExpr.getParent() = forBody
                // `for` statement with block and only containing ExprStmt
                or (
                    repeatingExpr.getParent().(ExprStmt).getEnclosingStmt() = forBody
                    and forBody.(BlockStmt).getNumStmt() = 1
                )
            )
            and repeatingExpr = getAStringRepeatingExpr(charSequenceExpr)
        )
        // String being repeated using `Collections.nCopies` and joining its elements
        or exists(MethodAccess nCopiesCall |
            nCopiesCall.getMethod() instanceof CollectionsNCopiesMethod
            and charSequenceExpr = nCopiesCall.getArgument(1)
        |
        // String.join("", Collections.nCopies(...))
            DataFlow::localFlow(DataFlow::exprNode(nCopiesCall), DataFlow::exprNode(repeatingExpr.(IterableNoDelimiterJoiningCall).getJoinedArgument()))
            // Or joining elements in loop
            or exists(EnhancedForStmt forStmt, Stmt forBody, Variable stringVar |
                forBody = forStmt.getStmt()
                and DataFlow::localFlow(DataFlow::exprNode(nCopiesCall), DataFlow::exprNode(forStmt.getExpr()))
                and stringVar = forStmt.getVariable().getVariable()
            |
                (
                    // `for` statement without block directly containing ExprStmt
                    repeatingExpr.getParent() = forBody
                    // `for` statement with block and only containing ExprStmt
                    or (
                        repeatingExpr.getParent().(ExprStmt).getEnclosingStmt() = forBody
                        and forBody.(BlockStmt).getNumStmt() = 1
                    )
                )
                and repeatingExpr = getAStringRepeatingExpr(stringVar.getAnAccess())
            )
        )
    )
// String.repeat(...) does not directly work for CharSequence, but since result is likely String
// anyways, it might be easiest to call charSequence.toString().repeat(...)
select repeatingExpr, "Repeats $@ CharSequence expression manually", charSequenceExpr, "this"
