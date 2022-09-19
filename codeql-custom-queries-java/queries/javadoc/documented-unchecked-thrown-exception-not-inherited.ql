/**
 * Finds methods which override a method documenting a thrown unchecked exception, but
 * which do not themselves document that unchecked exception as well. When the exception
 * is neither listed in the `throws` clause nor documented with `@throws` it will be
 * omitted from the documentation for the overriding method.
 * 
 * @kind problem
 */

import java

string getADocumentedThrownExceptionName(Callable callable) {
    exists(Javadoc javadoc, ThrowsTag throwsTag |
        javadoc.getCommentedElement() = callable
        and throwsTag.getParent() = javadoc
        and result = throwsTag.getExceptionName()
    )
}

Class getExceptionClass(string exceptionName, CompilationUnit compilationUnit) {
    // Currently does not check precedence in case type is ambiguous, but should suffice for
    // most cases
    result.hasQualifiedName("java.lang", exceptionName)
    or result.hasQualifiedName(compilationUnit.getPackage().getName(), exceptionName)
    or exists(Import import_ |
        import_.getCompilationUnit() = compilationUnit
        and result.getName() = exceptionName
    |
        result = [
            import_.(ImportOnDemandFromPackage).getAnImport(),
            import_.(ImportOnDemandFromType).getAnImport(),
            import_.(ImportStaticOnDemand).getATypeImport(),
            import_.(ImportStaticTypeMember).getATypeImport()
        ]
    )
}

predicate isPubliclyVisible(Modifiable m) {
    m.isProtected() or m.isPublic()
}

from Method method, Method overridden, UncheckedThrowableType exceptionClass
where
    method.getASourceOverriddenMethod() = overridden
    // Overridden documents thrown unchecked exception
    and exceptionClass = getExceptionClass(getADocumentedThrownExceptionName(overridden), overridden.getCompilationUnit())
    and isPubliclyVisible(method)
    and isPubliclyVisible(method.getDeclaringType())
    // Check if intention is that method is properly documented
    and (
        exists(method.getDoc().getJavadoc())
        or exists(method.getDeclaringType().getDoc().getJavadoc())
    )
    // And overriding method also seems to throw that unchecked exception
    and (
        exists(ThrowStmt throwStmt |
            throwStmt.getEnclosingCallable() = method
            and throwStmt.getThrownExceptionType() = exceptionClass
        )
        or exists(Call call, Callable callee |
            call.getEnclosingCallable() = method
            and callee = call.getCallee()
        |
            callee.getAThrownExceptionType() = exceptionClass
            or getADocumentedThrownExceptionName(callee) = exceptionClass.getName()
        )
    )
    // But it is neither listed in the `throws` clause nor in the documentation
    and not method.getAThrownExceptionType() = exceptionClass
    and not getADocumentedThrownExceptionName(method) = exceptionClass.getName()
select method, "Does not document thrown " + exceptionClass.getName() + " and documentation from $@ is not inherited",
    overridden, "overridden method"
