/**
 * Finds code which concatenates the string representation of a `java.nio.file.Path`
 * instance with a path string. It might be less error-prone to instead use one of the
 * `Path` methods, such as `Path.resolve`. (Note that this could introduce differences
 * in behavior, see the documentation of the respective method.)
 * 
 * For example:
 * ```java
 * Path myPath = ...;
 * resultPath = myPath + "/file.txt";
 * 
 * // Could be replaced with:
 * resultPath = myPath.resolve("file.txt");
 * ```
 * 
 * @kind problem
 */

import java

predicate isPathString(Expr e) {
    // String starting with separator
    e.(CompileTimeConstantExpr).getStringValue().charAt(0) = ["/", "\\"]
    // Or read of `java.io.File` constant
    or exists(Field f |
        f = e.(FieldRead).getField()
        and f.getDeclaringType() instanceof TypeFile
        and f.hasName([
            "separator",
            "separatorChar"
        ])
    )
}

predicate isOfPathType(Expr e) {
    e.getType().(RefType).getSourceDeclaration().getASourceSupertype*() instanceof TypePath
}

from AddExpr concatExpr
where
    concatExpr.getType() instanceof TypeString
    and exists(Expr leftOperand | leftOperand = concatExpr.getLeftOperand() |
        // Implicit conversion to String
        isOfPathType(leftOperand)
        // Or explicit `toString()` call
        or exists(MethodAccess toStringCall |
            leftOperand = toStringCall
            and toStringCall.getMethod() instanceof ToStringMethod
            and isOfPathType(toStringCall.getQualifier())
        )
    )
    // Only consider strings which look like a path to reduce false positives, e.g.
    // when Path is concatenated with log message
    and isPathString(concatExpr.getRightOperand())
select concatExpr, "String concatentation with Path"
