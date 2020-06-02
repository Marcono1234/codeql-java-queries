/**
 * Finds `InterruptedException`s being caught and ignored.
 * They should be either rethrown or at some later point the interrupt 
 * flag should be set again (`Thread.currentThread().interrupt()`).
 */

import java

from CatchClause catch
where
    catch.getACaughtType().hasQualifiedName("java.lang", "InterruptedException")
    and catch.getBlock().getNumStmt() = 0
select catch
