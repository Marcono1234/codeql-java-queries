/**
 * Finds calls which appear to manually retrieve repeated annotations.
 * The interface `AnnotatedElement` (and classes implementing it) provides methods
 * for this task which should be preferred:
 * - `getAnnotationsByType`
 * - `getDeclaredAnnotationsByType`
 */

import java
import semmle.code.java.dataflow.SSA
import lib.Annotations

class AnnotationRetrievingCall extends MethodAccess {
    private boolean supportsRepeatable;
    private string alternative;

    AnnotationRetrievingCall() {
        exists(Method m, string name | m = getMethod() and name = m.getName() |
            m.getDeclaringType().getSourceDeclaration().getASourceSupertype*().hasQualifiedName("java.lang.reflect", "AnnotatedElement")
            and (
                name = "getAnnotation" and supportsRepeatable = false and alternative = "getAnnotationsByType"
                or name = "getAnnotationsByType" and supportsRepeatable = true and alternative = "getAnnotationsByType"
                or name = "getDeclaredAnnotation" and supportsRepeatable = false and alternative = "getDeclaredAnnotationsByType"
                or name = "getDeclaredAnnotationsByType" and supportsRepeatable = true and alternative = "getDeclaredAnnotationsByType"
            )
        )
    }

    Expr getAnnotationTypeArg() {
        result = getArgument(0)
    }

    /**
     * Holds if the called method supports indirect lookup for repeatable annotation types.
     */
    predicate supportsRepeatable() {
        supportsRepeatable = true
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

from AnnotationRetrievingCall retrievingCall, TypeLiteral annTypeLiteral, AnnotationType annType, AnnotationType repeatableAnnType
where
    annType = annTypeLiteral.getTypeName().getType()
    and repeatableAnnType.getAnAnnotation().(RepeatableAnnotation).getContainingType() = annType
    // Ignore if containing annotation type is itself repeatable as well
    and not (
        retrievingCall.supportsRepeatable()
        and annType.getAnAnnotation() instanceof RepeatableAnnotation
    )
    // Ignore if containing annotation type has other elements
    and not exists(AnnotationElement otherElem |
        otherElem = annType.getAnAnnotationElement()
        and otherElem.getName() != "value"
    )
    and retrievingCall.getAnnotationTypeArg() = getDirectAccessOrSsa(annTypeLiteral)
select retrievingCall, "Manually retrieves repeated annotations, should use `" + retrievingCall.getAlternative() + "` with the repeatable annotation type @"
    + repeatableAnnType.getName() + " as argument"
