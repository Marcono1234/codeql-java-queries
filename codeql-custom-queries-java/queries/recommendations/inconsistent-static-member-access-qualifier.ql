/**
 * Finds inconsistent usage of a type qualifier for access of static members (field, method
 * and nested type). Only using a type qualifier for some expressions, but not for all can
 * cause confusion because another person reading the code might wonder whether both
 * expressions refer to the same member. For example:
 * ```java
 * import static java.lang.String.format;
 * 
 * ...
 * 
 * s1 = String.format(pattern, args);
 * s2 = format(pattern, args);
 * ```
 * 
 * @kind problem
 */

import java

predicate isInSubtypeOf(Expr e, RefType t) {
    e.getEnclosingCallable().getDeclaringType().getASourceSupertype*() = t
}

predicate areRelevantFieldAccesses(FieldAccess qualified, FieldAccess unqualified) {
    exists(Field f |
        f.isStatic()
    	and f = qualified.getField()
        and f = unqualified.getField()
        and qualified.getQualifier() instanceof TypeAccess
        and not exists(unqualified.getQualifier())
        // Ignore unqualified access as part of field initialization
        and not exists(AssignExpr assign |
            assign.getRhs() = f.getInitializer()
            and assign.getDest() = unqualified
        )
        // Ignore if qualified access cannot be converted to unqualified access
        and not exists(RefType declaringType |
            declaringType = f.getDeclaringType()
            and isInSubtypeOf(unqualified, declaringType)
            and not isInSubtypeOf(qualified, declaringType)
        )
    )
}

predicate areRelevantMethodAccesses(MethodAccess qualified, MethodAccess unqualified) {
    exists(Method m |
        m.isStatic()
        and m = qualified.getMethod().getSourceDeclaration()
        and m = unqualified.getMethod().getSourceDeclaration()
        and qualified.getQualifier() instanceof TypeAccess
        and not exists(unqualified.getQualifier())
        // Ignore implicit qualified access in synthetic method ref method
        and not any(MemberRefExpr e).asMethod() = qualified.getEnclosingCallable()
        // Ignore if qualified access cannot be converted to unqualified access
        and not exists(RefType declaringType |
            declaringType = m.getDeclaringType()
            and isInSubtypeOf(unqualified, declaringType)
            and not isInSubtypeOf(qualified, declaringType)
        )
    )
}

predicate areRelevantTypeAccesses(TypeAccess qualified, TypeAccess unqualified) {
    exists(RefType t |
        t.isStatic()
        and t = qualified.getType()
        and t = unqualified.getType()
        and qualified.getQualifier() instanceof TypeAccess
        and not exists(unqualified.getQualifier())
        // Ignore synthetic type access in functional expressions, see https://github.com/github/codeql/issues/3648
        // TODO: Maybe need to ignore more cases
        and not exists(FunctionalExpr funcExpr |
            funcExpr = qualified.getParent+()
            or funcExpr = unqualified.getParent+()
        )
        // Ignore access of type declared in same compilation unit, where the enclosing
        // type affects whether unqualified access is possible
        and not t.getCompilationUnit() = unqualified.getCompilationUnit()
    )
}

from Expr qualified, Expr unqualified
where
    qualified.getCompilationUnit() = unqualified.getCompilationUnit()
    and (
        areRelevantFieldAccesses(qualified, unqualified)
        or areRelevantMethodAccesses(qualified, unqualified)
        or areRelevantTypeAccesses(qualified, unqualified)
    )
select qualified, "Uses qualifier, but $@ expression does not use qualifier", unqualified, "this"
