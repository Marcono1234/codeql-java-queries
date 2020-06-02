/**
 * Finds `Throwable`s or `Error`s being caught and ignored. This could 
 * hide severe issues which could then later cause the complete application 
 * to break, e.g. `VirtualMachineError`s.
 */

import java

predicate isError(RefType t) {
    t.hasQualifiedName("java.lang", "Throwable")
    or t.hasQualifiedName("java.lang", "Error")
}

from CatchClause catch
where
    isError(catch.getACaughtType())
    and catch.getBlock().getNumStmt() = 0
select catch
