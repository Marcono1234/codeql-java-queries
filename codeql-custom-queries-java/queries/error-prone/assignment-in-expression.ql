/**
 * Finds assignments which appear as part of another expression, i.e. the
 * assignment result is not discarded. This decreases readability and might
 * also indicate a bug in case the intention was to write `==` but by
 * accident only `=` was written.
 * E.g.:
 * ```java
 * String result;
 * doSomething(result = getResult());
 * ```
 * Should instead be written as:
 * ```java
 * String result = getResult();
 * doSomething(result);
 * `` 
 */

import java
import lib.Expressions

from Assignment assign
where
    // Result is not discarded
    not assign instanceof StmtExpr
    // Ignore if assignment appears in loop condition, e.g. `while ((r = read()) != -1)`
    and not any(LoopStmt l).getCondition() = assign.getParent+()
    // Ignore chained assignments in the form `a = b = 1`
    and not (
        assign instanceof AssignExpr
        and any(AssignExpr e).getRhs() = assign
    )
    // Ignore assignment in return, this is still somewhat readable, e.g. `return f = getResult();`
    and not any(ReturnStmt r).getResult() = assign
select assign, "Should write assignment as separate statement for better readability"
