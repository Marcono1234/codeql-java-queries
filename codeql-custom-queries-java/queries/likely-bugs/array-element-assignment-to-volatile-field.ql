/**
 * Finds array element assignments to a `volatile` array field.
 * The `volatile` keyword only makes assignment to the field thead-safe,
 * but not element assignments to the field value. These should be
 * guarded using other synchronization measures.
 * 
 * @kind problem
 */

import java
import lib.ConcurrencyLib

from ArrayAccess arrayAccess, Assignment assignment
where
    arrayAccess.getArray().(FieldRead).getField().isVolatile()
    and assignment.getDest() = arrayAccess
    // Ignore if there might be synchronization guarding the assignment
    and not isExprSynchronized(assignment)
select assignment, "Array element assignment is not thread-safe despite array field being volatile"
