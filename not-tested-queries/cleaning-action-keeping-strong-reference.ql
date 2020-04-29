/**
 * Finds usages of `java.lang.ref.Cleaner` where the cleaning Runnable keeps
 * a strong reference to the enclosing class whose resources should be cleaned,
 * therefore preventing cleaning.
 */

import java
import semmle.code.java.dataflow.DataFlow

class TypeRunnable extends Interface {
    TypeRunnable() {
        hasQualifiedName("java.lang", "Runnable") 
    }
}

class RunMethod extends Method {
    RunMethod() {
        getDeclaringType() instanceof TypeRunnable
        and hasStringSignature("run()")
    }
}

Expr referenceToClassInstance(Class referenced) {
    // Reference to class via `this`, e.g. `Enclosing.this`
    result.(ThisAccess).getType() = referenced
    // Reference to class via non-static method access
    or exists (MethodAccess methodAccess |
        result = methodAccess
        and methodAccess.getReceiverType() = referenced
        and not methodAccess.getMethod().isStatic()
    )
    // Reference to class via non-static field access
    or exists (FieldAccess fieldAccess, Field field |
        result = fieldAccess
        and field = fieldAccess.getField()
        and not field.isStatic()
        and referenced.getAnAncestor() = field.getDeclaringType()
    )
}

/**
 * Returns a creation of a Runnable which references an instance
 * of `referenced`. `reason` should be an unrestricted argument and
 * will be set to a string explaining why the returned expression references
 * an instance of the specified class.
 */
Expr getRunnableCreationReferencingInstance(Class referenced, string reason) {
    // Creation of non-static inner class
    exists (ConstructorCall constructorCall, Class constructed |
        result = constructorCall
        and constructed = constructorCall.getConstructedType()
        and constructed.getAnAncestor() instanceof TypeRunnable
        and constructed.getEnclosingType() = referenced
        and not constructed.isStatic()
        and reason = "Creation of non-static cleaning class"
    )
    // Lambda referencing class instance
    or exists (LambdaExpr lambdaExpr |
        result = lambdaExpr
        and lambdaExpr.asMethod().getAnOverride() instanceof RunMethod
        and exists (Expr enclosingReference |
            enclosingReference = referenceToClassInstance(referenced)
            |
            enclosingReference.getParent*() = lambdaExpr.getExprBody()
            or enclosingReference.getEnclosingStmt() = lambdaExpr.getStmtBody()
        )
        and reason = "Cleaning lambda referencing enclosing instance"
    )
    // Method reference referencing non-static method of class instance
    or exists (MemberRefExpr memberRefExpr, Callable referencedCallable |
        result = memberRefExpr
        and memberRefExpr.asMethod().getAnOverride() instanceof RunMethod
        and referencedCallable = memberRefExpr.getReferencedCallable()
        and not referencedCallable.isStatic()
        and referenced.getAnAncestor*() = referencedCallable.getDeclaringType()
        and reason = "Cleaning action is method reference to non-static method of enclosing instance"
    )
}

class CleanerRegisterMethod extends Method {
    CleanerRegisterMethod() {
        getDeclaringType().hasQualifiedName("java.lang.ref", "Cleaner")
        and hasStringSignature("register(Object, Runnable)")
    }
}

Expr getEnclosingCleaningReference(Class enclosingClass, string reason) {
    exists (MethodAccess call | call.getMethod() instanceof CleanerRegisterMethod |
        // Check that Cleaner.register is waiting for instance of `enclosingClass`
        // to be become unreachable
        call.getArgument(0).(ThisAccess).getType() = enclosingClass
        // Find a cleaning Runnable which keeps a strong reference to an `enclosingClass` instance
        and result = getRunnableCreationReferencingInstance(enclosingClass, reason)
        and DataFlow::localFlow(DataFlow::exprNode(result), DataFlow::exprNode(call.getArgument(1)))
    )
}

from Class enclosingClass, Expr enclosingRef, string reason
where 
    enclosingRef = getEnclosingCleaningReference(enclosingClass, reason)
select enclosingRef, reason
