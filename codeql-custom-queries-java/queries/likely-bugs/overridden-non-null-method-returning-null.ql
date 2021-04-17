/**
 * Finds methods which are annotated with an annotation indicating that
 * the method might return `null`, or which likely return `null`, but
 * override a method which guarantees non-`null` return values.
 */

import java
import semmle.code.java.dataflow.Nullness
import lib.Nullness

Annotation getAReturnTypeAnnotation(Method m) {
    // Might be incomplete, see also https://github.com/github/codeql/issues/3417
    exists (TypeAccess typeAccess |
        typeAccess.getParent() = m
        and result = typeAccess.getAnAnnotation()
    ) 
}

Annotation getAMethodOrReturnTypeAnnotation(Method m) {
    result = getAReturnTypeAnnotation(m)
    or result = m.getAnAnnotation()
}

class RequiredNonNullMethod extends Method {
    RequiredNonNullMethod() {
        getAMethodOrReturnTypeAnnotation(this) instanceof NonNullAnnotation 
    }
}

class NullableMethod extends Method {
    NullableMethod() {
        getAMethodOrReturnTypeAnnotation(this) instanceof NullableAnnotation
        or exists (ReturnStmt returnStmt |
            returnStmt.getEnclosingCallable() = this
            and returnStmt.getResult() = nullExpr()
        )
    }
}

from RequiredNonNullMethod requiredNonNull, NullableMethod nullableMethod
where
    nullableMethod.getAnOverride*() = requiredNonNull
select requiredNonNull, nullableMethod
