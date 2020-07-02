/**
 * Finds methods which override a method, but simply call the parent
 * implementation without doing anything else, e.g.:
 * ```
 * class MyClass {
 *     @Override
 *     public String toString() {
 *         return super.toString();
 *     }
 * }
 * ```
 *
 * If there is no difference in modifiers or annotations and no comment
 * or javadoc, then overriding the method likely adds no value and only
 * clutters the class.
 */

import java

predicate callsSuper(Method m, SuperMethodAccess call) {
    exists (Method overridden |
        overridden = m.getAnOverride()
        and call.getMethod() = overridden
        // Ignore if method is overridden to make it synchronized
        and (overridden.isSynchronized() or not m.isSynchronized())
        // Only consider method if it has the same visibility
        and (
            m.isPublic() and overridden.isPublic()
            or m.isProtected() and overridden.isProtected()
            or m.isPackageProtected() and overridden.isPackageProtected()
        )
        // Ignore if method adds annotations which are not present on overridden
        and forall (Annotation annotation |
            annotation = m.getAnAnnotation()
            and not annotation instanceof OverrideAnnotation
        |
            overridden.getAnAnnotation().getType() = annotation.getType()
        )
    )
    // Make sure parameters are passed in the same order
    and forall (int paramIndex, Parameter param |
        param = m.getParameter(paramIndex)
    |
        call.getArgument(paramIndex) = param.getAnAccess().(RValue)
    )
}

from Method m, Stmt s
where
    s.getEnclosingStmt() = m.getBody()
    // Stmt is the only one in the method
    and not exists (Stmt other |
        other != s
        and other.getEnclosingStmt() = m.getBody()
    )
    and (
        callsSuper(m, s.(ExprStmt).getExpr())
        or callsSuper(m, s.(ReturnStmt).getResult())
    )
    // Ignore if method is overridden to prevent subclasses from overriding it
    and not m.isFinal()
    and not exists (Javadoc javadoc |
        m = javadoc.getCommentedElement()
    )
    // Ignore if there is a comment within the method
    and m.getNumberOfCommentLines() = 0
select m, s
