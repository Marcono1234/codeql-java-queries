/**
 * Finds classes which store a reference to `this` (i.e. their own instance)
 * in one of its fields. This is error-prone because it can easily lead to
 * infinite recursion when someone tries to use the value of that field.
 * 
 * @kind problem
 */

 // Note: Could improve this in the future by also considering containers
 // such as sets, lists or maps

import java

from Expr selfStoringExpr, Field f
where
    // Directly assigns `this` to field
    exists(FieldWrite fieldWrite | fieldWrite = selfStoringExpr |
        fieldWrite.isOwnFieldAccess()
        and fieldWrite.getField() = f
        and fieldWrite.getRhs().(ThisAccess).isOwnInstanceAccess()
    )
    // Or stores `this` as array element of own array
    or exists(AssignExpr assign, FieldRead fieldRead | assign = selfStoringExpr |
        fieldRead = assign.getDest().(ArrayAccess).getArray()
        and fieldRead.isOwnFieldAccess()
        and fieldRead.getField() = f
        and assign.getRhs().(ThisAccess).isOwnInstanceAccess()
    )
select selfStoringExpr, "Stores a reference to itself in own field $@", f, f.getName()
