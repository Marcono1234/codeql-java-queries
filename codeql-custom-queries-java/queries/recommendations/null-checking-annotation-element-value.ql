/**
 * Finds `null` checks being performed for the value of an annotation element.
 * Annotation element values can never be `null` (unless a regular class implements
 * the annotation interface and then returns `null`), so performing a `null` check
 * for them is redundant.
 * 
 * See also [JLS 16 §9.7.1](https://docs.oracle.com/javase/specs/jls/se16/html/jls-9.html#jls-9.7.1).
 */

import java
import semmle.code.java.dataflow.SSA
import semmle.code.java.dataflow.NullGuards

// Only use SSA but not local data flow to avoid false positives when variable
// is assigned at multiple locations or is re-assigned
Expr getDirectAccessOrSsa(Expr source) {
    source = result
    or exists (SsaExplicitUpdate ssaVar |
        ssaVar.getDefiningExpr().(VariableAssign).getSource() = source
        and result = ssaVar.getAUse()
    )
}

from MethodAccess annotationElementCall, AnnotationElement annotationElement, Expr nullGuard, Expr nullGuardSink
where
    // AnnotationElement is also a Method, see https://github.com/github/codeql/issues/5399
    annotationElementCall.getMethod() = annotationElement
    // Use `isnull=true` to exclude expressions which can only check for non-null, e.g. `instanceof`
    and nullGuard = basicOrCustomNullGuard(nullGuardSink, _, true)
    and (
        // Checking array element of annotation element value
        (
            annotationElement.getType() instanceof Array
            // Flow from call -> array access -> null check
            and exists (ArrayAccess arrayAccess |
                arrayAccess.getArray() = getDirectAccessOrSsa(annotationElementCall)
                and nullGuardSink = getDirectAccessOrSsa(arrayAccess)
            )
        )
        // Checking annotation element value
        or nullGuardSink = getDirectAccessOrSsa(annotationElementCall)
    )
select nullGuard, "Redundant null check for annotation element value obtained from $@", annotationElementCall, "here"
