/**
 * Finds multiple cast expressions which cast the same variable to the same type.
 * To avoid this repetition it might be better to introduce a local variable storing
 * the cast result and perform actions on that variable.
 * 
 * @kind problem
 */

/* 
 * Has some overlap with query 'variable-always-cast-to-same-type.ql'
 * However, this query here is mostly about detecting casts which are guarded by an
 * `instanceof` check or similar and for which a new local variable should be
 * introduced.
 */

import java

import lib.Locations
import lib.VarAccess

from CastExpr castExpr, CastExpr otherCastExpr, Type targetType
where
    castExpr.getTypeExpr().getType() = targetType
    and otherCastExpr.getTypeExpr().getType() = targetType
    and castExpr.getEnclosingCallable() = otherCastExpr.getEnclosingCallable()
    and accessSameVarOfSameOwner(castExpr.getExpr(), otherCastExpr.getExpr())
    and castExpr != otherCastExpr
    // Ignore if first cast occurs inside `if` statement condition, then it can most likely
    // not easily be extracted
    and not any(IfStmt s).getCondition().getAChildExpr+() = castExpr
    // To avoid reporting same casts multiple times in different order, make sure the
    // the main reported cast comes before the other ones
    and isBefore(castExpr.getLocation(), otherCastExpr.getLocation())
select castExpr, "Performs the same cast as $@", otherCastExpr, "this"
