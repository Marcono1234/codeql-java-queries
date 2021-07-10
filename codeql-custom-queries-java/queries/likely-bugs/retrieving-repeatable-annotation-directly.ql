/**
 * Finds calls to methods retrieving only direct annotations, but where the requested
 * annotation type is repeatable. Therefore when the annotation appears multiple times
 * on an annotated element, the retrieving call will have no result since an implicit
 * container annotation is used for the repeated annotations. To solve this, one of
 * the retrieval methods supporting indirect lookup should be used.
 */

import java
import semmle.code.java.dataflow.SSA
import lib.Annotations

/**
 * Call of a method which only supports retrieving direct annotations, but does not
 * support indirect retrieval of repeated annotations.
 */
class DirectAnnotationRetrievingCall extends MethodAccess {
    private string alternative;

    DirectAnnotationRetrievingCall() {
        exists(Method m, string name | m = getMethod() and name = m.getName() |
            m.getDeclaringType().getSourceDeclaration().getASourceSupertype*().hasQualifiedName("java.lang.reflect", "AnnotatedElement")
            and (
                name = "getAnnotation" and alternative = "getAnnotationsByType"
                or name = "getDeclaredAnnotation" and alternative = "getDeclaredAnnotationsByType"
                or name = "isAnnotationPresent" and alternative = "getAnnotationsByType(...).length != 0"
            )
        )
    }

    Expr getAnnotationTypeArg() {
        result = getArgument(0)
    }

    string getAlternative() {
        result = alternative
    }
}

// Only use SSA but not local data flow to avoid false positives when variable
// is assigned at multiple locations or is re-assigned
Expr getDirectAccessOrSsa(Expr source) {
    source = result
    or exists (SsaExplicitUpdate ssaVar |
        ssaVar.getDefiningExpr().(VariableAssign).getSource() = source
        and result = ssaVar.getAUse()
    )
}

from DirectAnnotationRetrievingCall retrievingCall, TypeLiteral annTypeLiteral, AnnotationType annType
where
    retrievingCall.getAnnotationTypeArg() = getDirectAccessOrSsa(annTypeLiteral)
    and annType = annTypeLiteral.getTypeName().getType()
    and annType.getAnAnnotation() instanceof RepeatableAnnotation
select retrievingCall, "Retrieves only direct annotations of repeatable annotation type; should use `" + retrievingCall.getAlternative() + "`"
