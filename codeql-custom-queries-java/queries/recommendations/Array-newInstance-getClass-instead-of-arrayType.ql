/**
 * Finds usage of `Array.newInstance(...).getClass()` to create an array class with a
 * specific component type. Java 12 added `Class.arrayType()` which should be used instead
 * because it makes the intention clearer.
 */

import java

from MethodAccess newArrayCall, MethodAccess getClassCall
where
    // Either newInstance(Class, int) or newInstance(Class, int...)
    newArrayCall.getMethod().hasQualifiedName("java.lang.reflect", "Array", "newInstance")
    // When using newInstance(Class, int...) make sure that number of dimensions is 1; otherwise cannot use arrayType()
    and newArrayCall.getNumArgument() <= 2
    and (newArrayCall.getArgument(1).getType() instanceof Array implies count(newArrayCall.getArgument(1).(ArrayCreationExpr).getFirstDimensionSize()) = 1)
    and getClassCall.getMethod().hasStringSignature("getClass()")
    and getClassCall.getQualifier() = newArrayCall
select newArrayCall, "Should use Class.arrayType() instead"
