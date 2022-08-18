/**
 * Finds iteration over `Map.entrySet()` where iterating over `Map.keySet()` or `Map.values()`
 * would suffice. In that case iterating over `entrySet()` only makes the code more verbose.
 *
 * @kind problem
 */

// Similar to CodeQL's java/inefficient-key-set-iterator

import java

import lib.Expressions

class EntrySetMethod extends Method {
    EntrySetMethod() {
        hasStringSignature("entrySet()")
        and getDeclaringType().getASourceSupertype*().hasQualifiedName("java.util", "Map")
    }
}

from EnhancedForStmt forLoop, Variable loopVar, MethodAccess entrySetCall, string alternative
where
    forLoop.getExpr() = entrySetCall
    and entrySetCall.getMethod() instanceof EntrySetMethod
    and loopVar = forLoop.getVariable().getVariable()
    // And all access on the Entry are either getKey() or getValue() calls
    and forex(MethodAccess entryCall, string entryMethodSignature |
        entryCall.getQualifier() = loopVar.getAnAccess()
        and entryMethodSignature = entryCall.getMethod().getStringSignature()
    |
        entryMethodSignature = "getKey()"
        and alternative = "map.keySet()"
        or
        entryMethodSignature = "getValue()"
        and alternative = "map.values()"
    )
    // And entry is not leaked outside current callable
    and not isLeaked(loopVar.getAnAccess())
select entrySetCall, "Should iterate over " + alternative
