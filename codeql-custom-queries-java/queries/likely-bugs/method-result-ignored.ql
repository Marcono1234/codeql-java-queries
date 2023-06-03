/**
 * Finds method calls where the result of the call is ignored, despite the method being
 * annotated with `@CheckReturnValue`.
 * 
 * See also Error Prone pattern [CheckReturnValue](https://errorprone.info/bugpattern/CheckReturnValue).
 * 
 * @kind problem
 */

// This is also detected by IntelliJ IDEA, see https://youtrack.jetbrains.com/issue/IDEA-153192 and https://youtrack.jetbrains.com/issue/IDEA-158576

// Similar to CodeQL's `java/return-value-ignored` and `java/ignored-error-status-of-call`

import java

class CheckReturnValueAnnotation extends Annotation {
    CheckReturnValueAnnotation() {
        // Note: Ignore package name because annotation exists for JSR 305, Error Prone annotations, and SpotBugs annotations, ...
        getType().hasName("CheckReturnValue")
    }
}

class CanIgnoreReturnValueAnnotation extends Annotation {
    CanIgnoreReturnValueAnnotation() {
        // Note: Currently seems to only exist for Error Prone annotations, but to avoid false positives ignore the
        // package name here as well
        getType().hasName("CanIgnoreReturnValue")
    }
}

from MethodAccess call, Method m, RefType declaringType
where
    // Result of method call is ignored
    call instanceof ValueDiscardingExpr
    and m = call.getMethod().getSourceDeclaration()
    and declaringType = m.getDeclaringType()
    // Ignore if method has no return value (but declaring type might be annotated with CheckReturnValue)
    and not m.getReturnType() instanceof VoidType
    and (
        m.getAnAnnotation() instanceof CheckReturnValueAnnotation
        or
        not m.getAnAnnotation() instanceof CanIgnoreReturnValueAnnotation
        and (
            declaringType.getAnAnnotation() instanceof CheckReturnValueAnnotation
            or (
                declaringType.getPackage().getAnAnnotation() instanceof CheckReturnValueAnnotation
                and not declaringType.getAnAnnotation() instanceof CanIgnoreReturnValueAnnotation
            )
        )
    )
    // Ignore test classes
    // TODO: If possible make this more specific; there are cases where results in test classes
    // are relevant as well, for example incorrect usage of AssertJ
    and not call.getEnclosingCallable().getDeclaringType() instanceof TestClass
select call, "Result of this call should not be ignored"
