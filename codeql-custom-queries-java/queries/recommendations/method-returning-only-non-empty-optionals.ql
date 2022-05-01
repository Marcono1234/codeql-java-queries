/**
 * Finds methods which have `Optional` (or a primitive variant) as return type, but which
 * always return a non-empty `Optional`. To make the method easier to use, it should
 * directly return the result without wrapping it in an `Optional` first.
 */

import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.FlowSteps

import lib.Optionals

// Dataflow step which preserves the 'present' state of the Optional
// TODO: This is not actually a value step, but is used for local dataflow below; try to
//       solve this in a cleaner way
class OwnFieldStep extends AdditionalValueStep {
    override
    predicate step(DataFlow::Node node1, DataFlow::Node node2) {
        exists(PresentStatePreservingOptionalCall call |
            call = node2.asExpr()
            and call.getInputOptional() = node1.asExpr()
        )
    }
}

from Method m
where
    m.fromSource()
    and m.getReturnType().(RefType).getASourceSupertype*().getSourceDeclaration() instanceof Optional
    and forex(ReturnStmt returnStmt |
        returnStmt.getEnclosingCallable() = m
    |
        // Non-empty Optional flows to `return` statement
        exists(MethodAccess nonEmptyOptionalSource |
            nonEmptyOptionalSource.getMethod() instanceof NewNonEmptyOptionalMethod
            and DataFlow::localExprFlow(nonEmptyOptionalSource, returnStmt.getResult())
        )
        // And there is no alternative flow path where empty Optional flows to `return` statement
        // TODO: Probably rather ineffecient; maybe try using instead config with ConditionNode as 'sanitizer'
        and not exists(Expr emptyOptionalSource |
            DataFlow::localExprFlow(emptyOptionalSource, returnStmt.getResult())
            and not exists(MethodAccess nonEmptyOptionalSource |
                nonEmptyOptionalSource.getMethod() instanceof NewNonEmptyOptionalMethod
                and DataFlow::localExprFlow(nonEmptyOptionalSource, emptyOptionalSource)
            )
        )
    )
    // And is not overriding method which requires Optional as return type
    and not exists(m.getAnOverride())
    // And is not overridden; then external classes might override method as well
    and not exists(Method other | other.getAnOverride() = m)
    // And is not an interface default method, then it is likely overridden as well
    and not m.isDefault()
select m, "Method seems to always return non-empty Optional; could directly return result instead"
