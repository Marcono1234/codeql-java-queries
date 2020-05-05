/**
 * Finds methods which are annotated with an annotation indicating that
 * the method might return `null`, or which likely return `null`, but
 * override a method which guarantees non-`null` return values.
 */

import java
import semmle.code.java.dataflow.Nullness

Method overrideOrSelf(Method m) {
    result = m
    or result = m.getAnOverride()
}

class NonNullAnnotation extends Annotation {
    NonNullAnnotation() {
        // Ignore case due to the different existing annotations
        exists (string typeNameLower |
            typeNameLower = getType().getName().toLowerCase()
            |
            typeNameLower = "nonnull"
            or typeNameLower = "notnull"
        )
    }
}

class NullableAnnotation extends Annotation {
    NullableAnnotation() {
        // Ignore case due to the different existing annotations
        exists (string typeNameLower |
            typeNameLower = getType().getName().toLowerCase()
            |
            typeNameLower = "nullable"
        )
    }
}

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
    overrideOrSelf(nullableMethod) = requiredNonNull
select requiredNonNull, nullableMethod
