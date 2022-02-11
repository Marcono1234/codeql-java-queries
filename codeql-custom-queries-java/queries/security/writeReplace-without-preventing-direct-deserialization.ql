/**
 * Finds classes implementing `Serializable` which seem to write a serialization proxy
 * by defining `writeReplace`, but which do not define `readObject` to prevent direct
 * deserialization. This allows direct deserialization of the class without using the
 * proxy, potentially allowing an adversary to bypass validation checks.
 */

import java
import semmle.code.java.dataflow.DataFlow

import lib.JavaSerialization

from Class c, WriteReplaceSerializableMethod writeReplaceMethod
where
    c.fromSource()
    and writeReplaceMethod.getDeclaringType() = c
    // Does not return `this`; e.g. when writeReplace is only used to serialize empty
    // singleton instances
    and not exists(ReturnStmt returnStmt, ThisAccess thisAccess |
        returnStmt.getEnclosingCallable() = writeReplaceMethod
        and thisAccess.isOwnInstanceAccess()
        and DataFlow::localExprFlow(thisAccess, returnStmt.getResult())
    )
    // And there is no inherited readObject method which always throws
    and not exists(ReadObjectSerializableMethod readObjectMethod |
        readObjectMethod.getDeclaringType() = c.getASourceSupertype+()
        and readObjectMethod.getBody().(SingletonBlock).getStmt() instanceof ThrowStmt
    )
    // And class does not define readObject method
    and not any(ReadObjectSerializableMethod m).getDeclaringType() = c
select c, "Writes serialization proxy $@, but does not prevent direct deserialization", writeReplaceMethod, "here"
