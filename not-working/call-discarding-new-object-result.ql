/**
 * Finds method calls which discard the return value despite the called
 * method potentially creating a new object as result value:
 * ```
 * public static <T> List<T> combine(List<T> a, List<T> b) {
 *     List<T> result = new ArrayList<>(a.size() + b.size());
 *     result.addAll(a);
 *     result.addAll(b);
 *     return result;
 * }
 * 
 * ...
 * List<String> listA = ...
 * List<String> listB = ...
 * // Discards result; method call has therefore no effect
 * combine(listA, listB);
 * ```
 * This might indicate that the code is not working as intended or could
 * also hint that the method is used in an inefficient way.
 */

import java
import semmle.code.java.dataflow.DataFlow

class Import_ extends Import {
    predicate isImporting(RefType type) {
        this.(ImportType).getImportedType() = type
        or this.(ImportStaticTypeMember).getATypeImport() = type
        or this.(ImportOnDemandFromPackage).getAnImport() = type
        or this.(ImportOnDemandFromType).getAnImport() = type
        or this.(ImportStaticOnDemand).getATypeImport() = type
    }
}

class ReturningMethod extends Method {
    ReturningMethod() {
        exists (Expr newExpr, ReturnStmt returnStmt |
            newExpr.getEnclosingCallable() = this
            and (newExpr instanceof ClassInstanceExpr or newExpr instanceof ArrayCreationExpr)
            and returnStmt.getEnclosingCallable() = this
        |
            newExpr = returnStmt.getResult()
            or (
                DataFlow::localFlow(DataFlow::exprNode(newExpr), DataFlow::exprNode(returnStmt.getResult()))
                // Ignore if method stores result somewhere else, but only additionally returns it
                and not exists (Expr storingExpr |
                    (
                        exists (Assignment assign | assign.getRhs() = storingExpr)
                        or storingExpr instanceof Argument // Passing created object to other method
                    )
                    and DataFlow::localFlow(DataFlow::exprNode(newExpr), DataFlow::exprNode(storingExpr))
                )
            )
        )
    }
    
    Class getAThrownException() {
        result = getAThrownExceptionType()
        or exists (ThrowStmt throwStmt |
            throwStmt.getEnclosingCallable() = this
            and result = throwStmt.getThrownExceptionType()
        )
        // Verify exception type to ignore ambiguous Javadoc
        or result.getASourceSupertype*() instanceof TypeThrowable
        and exists (ThrowsTag throwsTag, string exceptionName |
            throwsTag.getParent+().(Javadoc).getCommentedElement() = this
            and exceptionName = throwsTag.getExceptionName()
        |
            result.getQualifiedName() = exceptionName
            or result.hasQualifiedName("java.lang", exceptionName)
            or result.hasQualifiedName(getCompilationUnit().getPackage().getName(), exceptionName)
            or exists (Import_ import_ |
                import_.getCompilationUnit() = getCompilationUnit()
                and import_.isImporting(result)
            )
        )
    }
}

from MethodAccess call, ReturningMethod returningMethod
where
    returningMethod.getSourceDeclaration().overridesOrInstantiates*(call.getMethod())
    and call.getParent() instanceof ExprStmt // Result is unused
    // Ignore if call happens in try stmt which appears to catch exception of call
    // Call might be used for validation purposes then
    and not exists (TryStmt tryStmt |
        tryStmt = call.getEnclosingStmt().getEnclosingStmt*()
        // Consider subclasses of both: catching more generic exception, catchting more specific exception
        and tryStmt.getACatchClause().getACaughtType().getASourceSupertype*() = returningMethod.getAThrownException().getASourceSupertype*()
    )
    // Ignore test methods; some use mocking frameworks where there is no actual result
    and not call.getEnclosingCallable() instanceof TestMethod
select call, "Method call result is discarded despite $@ returning a new object.", returningMethod, "this method implementation"
