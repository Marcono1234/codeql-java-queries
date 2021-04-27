/**
 * Finds labels on loop statements which are redundant and can be omitted
 * because all `break` and `continue` statements using the label would
 * still refer to the same loop statement, even without label.
 * E.g.:
 * ```java
 * // This label is redundant
 * Label:
 * for (int i = 0; i < length; i++) {
 *     if (condition) {
 *         break Label;
 *     }
 *     ...
 * }
 * ```
 */

import java

class LabeledBreakOrContinue extends Stmt {
    string label;

    LabeledBreakOrContinue() {
        label = this.(BreakStmt).getLabel()
        or label = this.(ContinueStmt).getLabel()
    }

    string getLabel() { result = label }

    /**
     * Holds if this `break` or `continue` statement would also apply to `loop`
     * if it was not labeled.
     */
    predicate appliesUnlabeledTo(LoopStmt loop) {
        loop.getBody() = getEnclosingStmt*()
        // There is no nested loop statement in between
        and not exists(LoopStmt nestedLoop |
            nestedLoop.getEnclosingStmt*() = loop.getBody()
            and nestedLoop.getBody() = getEnclosingStmt*()
        )
        // And in case this is a `break`, there is no `switch` statement in between;
        // in that case an unlabeled `break` would apply to that instead
        // Checking for `switch` expression is not necessary because the JLS does not permit breaking
        // an enclosing loop in that case
        and not (
            this instanceof BreakStmt and exists(SwitchStmt switchStmt |
                switchStmt.getAStmt() = getEnclosingStmt*()
                and switchStmt.getEnclosingStmt*() = loop.getBody()
            )
        )
    }
}

// TODO: Ignore cases where a deeply nested `break` or `continue` statement exists within loop
//       In such case a label might improve readability

from LoopStmt loop, LabeledStmt label, string labelName
where
    labelName = label.getLabel()
    and loop = label.getStmt()
    // Use `forex` to ignore unused labels
    and forex(LabeledBreakOrContinue breakOrContinue |
        breakOrContinue.getEnclosingStmt+() = loop.getBody()
        and labelName = breakOrContinue.getLabel()
    |
        breakOrContinue.appliesUnlabeledTo(loop)
    )
    // Ignore if there is an enclosing loop; label might improve readability then
    and not exists(LoopStmt enclosingLoop |
        enclosingLoop.getBody() = loop.getEnclosingStmt*()
    )
select label, "This label is redundant, all `break` and `continue` statements would also apply to this loop without label"
