/**
 * Finds serializable classes which declare a `writeObject` method, but also declare or
 * inherit a `writeReplace` method. In this case `writeObject` will not be called during
 * serialization.
 */

import java
import semmle.code.java.dataflow.DataFlow

import lib.JavaSerialization

from Class c, WriteReplaceSerializableMethod writeReplaceMethod, WriteObjectSerializableMethod writeObjectMethod
where
    c.fromSource()
    // writeReplace is declared or inherited
    and c.inherits(writeReplaceMethod)
    // Does not return `this`; e.g. when writeReplace is only used to serialize empty
    // singleton instances
    and not exists(ReturnStmt returnStmt, ThisAccess thisAccess |
        returnStmt.getEnclosingCallable() = writeReplaceMethod
        and thisAccess.isOwnInstanceAccess()
        and DataFlow::localExprFlow(thisAccess, returnStmt.getResult())
    )
    and writeObjectMethod.getDeclaringType() = c
select writeObjectMethod, "Has no effect due to $@ writeReplace method", writeReplaceMethod, "this"
