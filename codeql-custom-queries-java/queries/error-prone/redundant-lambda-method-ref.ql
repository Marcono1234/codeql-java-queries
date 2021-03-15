/**
 * Finds lambdas and method references which try to satify an interface
 * which the type on which the method reference is created, or whose
 * method is called by the lambda, already implements.
 * E.g.
 * ```
 * interface MyRunnable extends Runnable { }
 * 
 * MyRunnable myRun = ...
 * 
 * Runnable r = myRun::run;
 * // or
 * Runnable r = () -> myRun.run();
 * // Instead of simply writing
 * Runnable r = myRun;
 * ```
 */

import java

// Check if all params of `m` are the args of `call` (in the same order)
predicate callsWithSameArgs(Method m, MethodAccess call) {
    forall (int paramIndex, Parameter p | p = m.getParameter(paramIndex) |
        p = call.getArgument(paramIndex).(RValue).getVariable()
    )
}

// Check if the lambda is only performing `call`, but nothing else
// Though qualifier of `call` may perform other action
predicate isLambdaCallingOnly(LambdaExpr lambda, MethodAccess call) {
    // Either lambda is expression
    lambda.getExprBody() = call
    // Or lambda has block, in that case check call is only statement
    or exists(Block lambdaBlock |
        lambdaBlock = lambda.getStmtBody()
        and lambdaBlock.getNumStmt() = 1
        and exists (Stmt stmt |
            stmt = lambdaBlock.getLastStmt()
            and (
                // Lambda does not return a value
                call.getParent() = stmt.(ExprStmt)
                // Or lambda returns a value
                or call.getParent() = stmt.(ReturnStmt).getResult()
            )
        )
    )
}

predicate isOrOverrides(Method m, Method overridden) {
    m = overridden
    or m.overridesOrInstantiates(overridden)
}

predicate isRedundantLambda(LambdaExpr lambda) {
   exists (Method funcM, Method commonM, MethodAccess call | 
     	funcM = lambda.asMethod()
        and isOrOverrides(funcM, commonM)
        and isOrOverrides(call.getMethod(), commonM)
        and callsWithSameArgs(funcM, call)
        and isLambdaCallingOnly(lambda, call)
   )
}

from FunctionalExpr funcExpr
where
    // Check if referenced method is the functional method this method ref wants to satisfy
    exists (Method commonM | 
        isOrOverrides(funcExpr.asMethod(), commonM)
        and isOrOverrides(funcExpr.(MemberRefExpr).getReferencedCallable().(Method), commonM)
    )
    or isRedundantLambda(funcExpr)
select funcExpr
