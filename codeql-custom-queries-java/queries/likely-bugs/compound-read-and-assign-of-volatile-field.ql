/**
 * Finds expressions which perform a compound read and assign to a volatile field.
 * Expressions such as `i++` or `i += 1` are not atomic; between the the read of
 * the field value and the write of the updated value another thread might have
 * modified the value. This can lead to incorrect results when multiple threads
 * concurrently modify the field. To solve this either guard this section with
 * a lock or use the classes from the `java.util.concurrent.atomic` package,
 * such as `AtomicInteger`.
 * 
 * @kind problem
 */

import java
import lib.ConcurrencyLib

from Field f, Expr readAssign
where
    f.isVolatile()
    and (
        exists(UnaryAssignExpr unaryAssign | unaryAssign = readAssign |
            unaryAssign.getExpr().(FieldAccess).getField() = f
        )
        or exists(AssignOp compoundAssign | compoundAssign = readAssign |
            compoundAssign.getDest().(FieldAccess).getField() = f
        )
    )
    and not isExprSynchronized(readAssign)
select readAssign, "This assignment to a volatile field is not atomic"
