/**
 * Finds types implementing `java.io.Externable` and have a non-empty `writeExternal`
 * method, but which also declare or inherit a `writeReplace` method. In this case
 * `writeExternal` will not be called during serialization.
 */

import java
import semmle.code.java.dataflow.DataFlow

import lib.JavaSerialization

from RefType t, Method writeExternalMethod, WriteReplaceSerializableMethod writeReplaceMethod
where
    t.fromSource()
    and writeExternalMethod.getDeclaringType() = t
    and writeExternalMethod.getSourceDeclaration().getASourceOverriddenMethod*() instanceof ExternalizableWriteExternalMethod
    and not writeExternalMethod.isAbstract()
    // And method body is neither empty, nor always throws an exception
    and not (
        writeExternalMethod.getBody().getNumStmt() = 0
        or writeExternalMethod.getBody().(SingletonBlock).getStmt() instanceof ThrowStmt
    )
    and t.inherits(writeReplaceMethod)
    // Does not return `this`; e.g. when writeReplace is only used to serialize empty
    // singleton instances
    and not exists(ReturnStmt returnStmt, ThisAccess thisAccess |
        returnStmt.getEnclosingCallable() = writeReplaceMethod
        and thisAccess.isOwnInstanceAccess()
        and DataFlow::localExprFlow(thisAccess, returnStmt.getResult())
    )
select writeExternalMethod, "Non-empty writeExternal method is pointless due to $@ writeReplace method", writeReplaceMethod, "this"
