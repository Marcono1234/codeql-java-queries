/**
 * Finds usage of types or type members which have an "@API Guardian" annotation
 * indicating that the API is not stable. Relying on such an API can make upgrading
 * the dependency difficult if the functionality of the API is changed or removed
 * between versions.
 *
 * See https://github.com/apiguardian-team/apiguardian
 */

import java

class ApiAnnotation extends Annotation {
    ApiAnnotation() {
        this.getType().hasQualifiedName("org.apiguardian.api", "API")
    }
}

string getMessageForUsage(Annotatable annotatable, CompilationUnit accessingCompilationUnit) {
    exists (string apiStatus |
        apiStatus = annotatable.getAnAnnotation().(ApiAnnotation).getValue("status").(FieldAccess).getField().(EnumConstant).getName()
        and (
            (apiStatus = "INTERNAL" and result = "API is internal")
            or (apiStatus = "DEPRECATED" and result = "API is deprecated")
            or (
                apiStatus = "EXPERIMENTAL"
                // Ignore usage of experimental API if inside a test class
                // There it is not that problematic and for example a lot of JUnit
                // functionality is marked as experimental
                and not exists (TestClass testClass | testClass.getCompilationUnit() = accessingCompilationUnit)
                and result = "API is experimental"
            )
        )
    )
    // TODO: Not tested yet
    or exists (ApiAnnotation annotation, string accessingPackage |
        annotation = annotatable.getAnAnnotation().(ApiAnnotation)
        and accessingPackage = accessingCompilationUnit.getPackage().getName()
        and not exists (string consumerPackage |
            consumerPackage = annotation.getAValue("consumers").(CompileTimeConstantExpr).getStringValue()
            and (
                consumerPackage = "*"
                // TODO: Might not match correctly, see https://github.com/apiguardian-team/apiguardian/issues/16
                or exists (int asteriskIndex |
                    asteriskIndex = consumerPackage.indexOf("*")
                    and consumerPackage.prefix(asteriskIndex - 1) = accessingPackage.prefix(asteriskIndex - 1)
                )
            )
        )
        and result = "Package " + accessingPackage + " is not one of the allowed consumers"
    )
}

string getDescription(Annotatable annotatable) {
    if annotatable instanceof Callable then (
        result = "callable " + annotatable.(Callable).getDeclaringType().getQualifiedName() + "." + annotatable.(Callable).getStringSignature()
    ) else if annotatable instanceof Field then (
        result = "field " + annotatable.(Field).getDeclaringType().getQualifiedName() + "." + annotatable.(Field).getName()
    ) else if annotatable instanceof RefType then (
        result = "type " + annotatable.(RefType).getQualifiedName()
    ) else (
        // Should not happen, but to be safe fall back to toString to always
        // at least get any description
        result = annotatable.toString()
    )
}

/*
 * If annotatable does not have annotation, check declaring type
 * See https://apiguardian-team.github.io/apiguardian/docs/current/api/org/apiguardian/api/API.html
 */
RefType getDeclaringType(Annotatable annotatable) {
    not annotatable.getAnAnnotation() instanceof ApiAnnotation
    and result = [
        annotatable.(Member).getDeclaringType(),
        annotatable.(RefType).getEnclosingType()
    ]
}

from Expr expr, CompilationUnit compilationUnit, Annotatable annotatable, string message
where
    compilationUnit = expr.getCompilationUnit()
    and annotatable = getDeclaringType*([
        expr.(Call).getCallee(),
        expr.(MemberRefExpr).getReferencedCallable(),
        expr.(FieldAccess).getField(),
        expr.(TypeAccess).getType().(Annotatable)
    ])
    and message = getMessageForUsage(annotatable, compilationUnit)
select expr, "Usage of $@: " + message, annotatable, getDescription(annotatable)
