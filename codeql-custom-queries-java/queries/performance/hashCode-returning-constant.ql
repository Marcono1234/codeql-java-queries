/**
 * Finds `hashCode()` implementations which unconditionally return a constant value.
 * Classes using the hash code, such as `java.util.HashMap`, rely on it to distribute
 * unequal elements. Therefore returning a constant value can result in bad performance
 * for such classes because returning a constant renders `hashCode()` useless. The
 * calling classes always have to call `equals(Object)` to find out if two objects
 * are equal.
 */

import java

predicate isNonSingleton(Class c) {
    c.isAbstract()
    // Or has instance field
    or exists(Field f |
        f.getDeclaringType() = c
        and not f.isStatic()
    )
    // Or has constructor with parameter
    or if (
        exists(Constructor constructor |
            constructor.getDeclaringType() = c
            and constructor.getNumberOfParameters() > 0
        )
    ) then any()
    // In case no constructor with parameters exists, check for mutable inherited fields
    else (
        exists(Field f |
            f.getDeclaringType() = c.getASourceSupertype+()
            and not f.isStatic()
            and not f.isFinal()
        )
    )
}

from HashCodeMethod hashCodeMethod, ReturnStmt returnStmt
where
    returnStmt.getEnclosingCallable() = hashCodeMethod
    and returnStmt.getResult() instanceof CompileTimeConstantExpr
    and isNonSingleton(hashCodeMethod.getDeclaringType())
    // And return statement is unconditional
    and not any(ConditionNode n).getABranchSuccessor(_).getASuccessor*() = returnStmt
    // Ignore if inside `catch`
    and not any(CatchClause c).getBlock() = returnStmt.getEnclosingStmt+()
select returnStmt, "Returns constant value in hashCode() method"
