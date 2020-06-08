/**
 * Finds fully qualified names of types where the simple name could be
 * used instead:
 * ```
 * java.util.List<String> list = new java.util.ArrayList<>();
 * // instead of
 * List<String> list = new ArrayList<>();
 * ```
 */

import java

int getSourceLength(Top top) {
    exists (Location location |
        location = top.getLocation()
        // + 1 because both are inclusive
        and result = location.getEndColumn() - location.getStartColumn() + 1
    )
}

int getExpectedTypeParametersLength(TypeAccess typeAccess) {
    // Check ParameterizedType here to cover diamond (`<>`)
    if typeAccess.getType() instanceof ParameterizedType then (
        result = (
            // For `<` and `>`
            2
            // * 2 for `, `; - 1 because it only appears between two arguments
            + (count(typeAccess.getATypeArgument()) - 1).maximum(0) * 2
            + sum(Expr typeArg | typeArg = typeAccess.getATypeArgument() | getSourceLength(typeArg))
        )
    ) else (
        result = 0
    )
}

int getExpectedQualifierLength(TypeAccess typeAccess) {
    if typeAccess.hasQualifier() then (
        // 1 for `.`
        result = 1 + getExpectedTypeLength(typeAccess.getQualifier())
    ) else (
        result = 0
    )
}

int getExpectedTypeLength(TypeAccess typeAccess) {
    result = (
        typeAccess.getType().getErasure().toString().length()
        + getExpectedQualifierLength(typeAccess)
        + getExpectedTypeParametersLength(typeAccess)
        // Increase length for annotations (consider 1 space for each annotation)
        + count(typeAccess.getAnAnnotation())
        + sum(Annotation annotation | annotation = typeAccess.getAnAnnotation() | getSourceLength(annotation))
    )
}

string canUseImportForType(CompilationUnit source, RefType type) {
    // Check if there is already an import
    // Don't consider wildcard imports because there could be collisions
    exists (ImportType importDecl |
        importDecl.getImportedType() = type
        and result = "Can use existing import for " + type.getQualifiedName()
    )
    // Could also use static import for type
    or exists (ImportStaticTypeMember staticImportDecl |
        staticImportDecl.getATypeImport() = type
        and result = "Can use existing import for " + type.getQualifiedName()
    )
    // Check for no conflicting type
    or (
        not exists (TypeAccess typeAccess |
            typeAccess.getCompilationUnit() = source
            and typeAccess.getType().getErasure().getName() = type.getName()
        )
        // Make sure javadoc does not reference type
        and not exists (JavadocTag javadocTag |
            javadocTag.getLocation().getFile() = source
            and exists (javadocTag.getText().indexOf(type.getName()))
        )
        // Make sure javadoc inline tag does not reference type
        and not exists (JavadocText javadocText |
            javadocText.getLocation().getFile() = source
            and javadocText.getText().regexpMatch(".*\\{@.* .*" + type.getName() + ".*\\}.*")
        )
        and result = "Can add import for " + type.getQualifiedName()
    )
    // Check if enclosing type can be used
    or result = canUseImportForType(source, type.getEnclosingType())
}

/*
 * Calculates the expected length for a type access and compares it to
 * the actual length.
 * This is slightly error-prone because it has to make assumptions about
 * how annotations are placed and how type parameters are written.
 */
from TypeAccess typeAccess, Location location, int expectedLength, int actualLength, string importDescription
where
    typeAccess.getType() instanceof ClassOrInterface
    // Ignore GenericType because only occurs at declaration, which is irrelevant here
    and not typeAccess.getType() instanceof GenericType
    and location = typeAccess.getLocation()
    // Ignore type access spanning multiple lines
    and location.getNumberOfLines() = 1
    and expectedLength = getExpectedTypeLength(typeAccess)
    and actualLength = getSourceLength(typeAccess)
    and actualLength > expectedLength
    and importDescription = canUseImportForType(typeAccess.getCompilationUnit(), typeAccess.getType().getErasure())
select typeAccess, importDescription/* For debugging: */, expectedLength, actualLength
