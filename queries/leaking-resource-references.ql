/**
 * Finds potential cases where a class is managing resources which
 * are released when the class instance is garbage collected, e.g.
 * through the `finalize` method or a `Cleaner`, but the class also
 * has public methods which return a reference to the resources.
 *
 * This is error-prone because a caller of these methods might forget
 * to keep a strong reference to the instance containing the resources
 * and therefore can experience at random (when the garbage collection
 * happens) that the resources have been released.
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

Expr getRunnableCreation(Variable var) {
    exists (ConstructorCall constructorCall |
        result = constructorCall
        and constructorCall.getConstructedType().getAnAncestor() instanceof TypeRunnable
        and constructorCall.getAnArgument() = var.getAnAccess().(RValue)
    )
    or exists (LambdaExpr lambdaExpr |
        result = lambdaExpr
        and lambdaExpr.asMethod().getAnOverride() instanceof RunMethod
        and (
            var.getAnAccess().(RValue).getParent*() = lambdaExpr.getExprBody()
            or var.getAnAccess().(RValue).getEnclosingStmt() = lambdaExpr.getStmtBody()
        )
    )
}

class CleanerRegisterMethod extends Method {
    CleanerRegisterMethod() {
        getDeclaringType().hasQualifiedName("java.lang.ref", "Cleaner")
        and hasStringSignature("register(Object, Runnable)")
    }
}

predicate isCleaned(Variable var) {
    exists (MethodAccess call |
        call.getEnclosingCallable() instanceof FinalizeMethod
        and call.getQualifier() = var.getAnAccess()
    )
    or exists (MethodAccess call | call.getMethod() instanceof CleanerRegisterMethod |
        DataFlow::localFlow(DataFlow::exprNode(getRunnableCreation(var)), DataFlow::exprNode(call.getArgument(1)))
    )
}

from Method method, ReturnStmt returnStmt, Field field
where 
    returnStmt.getEnclosingCallable() = method
    and method.isPrivate()
    and field.getAnAccess() = returnStmt.getResult()
    and isCleaned(field)
select returnStmt
