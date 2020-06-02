/**
 * Finds classes which implement `java.lang.Appendable`, but do not properly
 * handle `null` arguments for `append(...)`.
 * They should treat `null` as `"null"`, as required by the method contract.
 */

import java

class AppendMethod extends Method {
    AppendMethod() {
        getDeclaringType().hasQualifiedName("java.lang", "Appendable")
        and hasStringSignature("append(CharSequence)")
    }
}

class AppendIndicesMethod extends Method {
    AppendIndicesMethod() {
        getDeclaringType().hasQualifiedName("java.lang", "Appendable")
        and hasStringSignature("append(CharSequence, int, int)")
    }
}

class NullStringLiteral extends CompileTimeConstantExpr {
    NullStringLiteral() {
        getStringValue() = "null" 
    }
}

predicate callsAppendDelegate(Method appendMethod) {
    exists (Method delegateMethod |
        delegateMethod.getAnOverride*() instanceof AppendMethod
        and appendMethod.calls(delegateMethod)
    )
}

predicate considersIndices(Method appendIndicesMethod, NullStringLiteral nullString) {
    exists (RValue startIndexRead, RValue endIndexRead |
        startIndexRead = appendIndicesMethod.getParameter(1).getAnAccess()
        and endIndexRead = appendIndicesMethod.getParameter(2).getAnAccess()
        // Make sure that start and end indices are considered when "null"
        // is used
        and startIndexRead.getParent*() = nullString.getParent()
        and endIndexRead.getParent*() = nullString.getParent()
    )
}

predicate callsAppendIndicesDelegate(Method appendMethod) {
    exists (Method delegateMethod |
        delegateMethod.getAnOverride*() instanceof AppendIndicesMethod
        and appendMethod.calls(delegateMethod)
    )
}

from Method appendMethod
where
    (
        appendMethod.getAnOverride() instanceof AppendMethod
        and not (
            // Either handles `null` -> `"null"`
            exists (NullStringLiteral nullString |
                nullString.getEnclosingCallable() = appendMethod
            )
            // Or delegates it
            or callsAppendDelegate(appendMethod)
        )
    )
    or (
        appendMethod.getAnOverride() instanceof AppendIndicesMethod
        and not (
            // Either handles `null` -> `"null"`
            exists (NullStringLiteral nullString |
                nullString.getEnclosingCallable() = appendMethod
                // If `null` -> `"null"`, then must also apply start and end index
                // arguments to "null"
                and considersIndices(appendMethod, nullString)
            )
            // Or delegates it
            or callsAppendIndicesDelegate(appendMethod)
        )
    )
select appendMethod
