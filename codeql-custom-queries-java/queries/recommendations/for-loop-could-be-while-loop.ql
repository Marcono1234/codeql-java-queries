/**
 * Finds `for` loops which only defined a loop condition and could therefore
 * be replaced with a `while` loop over that condition.
 * 
 * Using a `while` loop can improve readability because the intended behavior
 * might be more obvious there.
 */

import java

from ForStmt forLoop
where
    // Make sure loop has condition, ignore infinite `for(;;)`
    exists(forLoop.getCondition())
    and not exists(forLoop.getAnInit())
    and not exists(forLoop.getAnUpdate())
select forLoop, "This `for` loop could be replaced with a `while` loop"
