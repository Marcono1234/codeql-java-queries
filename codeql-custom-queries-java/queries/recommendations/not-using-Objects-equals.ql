/**
 * Finds `equals(Object)` calls which are guarded by a `null` check and compare
 * the argument with `null` in case the call receiver object is `null`. Such code
 * can be replaced with `java.util.Objects.equals(Object, Objects)` which behaves
 * the same way but increases readability.
 */

import java
import semmle.code.java.controlflow.Guards
import lib.VarAccess

from EqualityTest nullCheck, boolean checksNull, ConditionBlock conditionBlock, MethodAccess equalsCall, EqualityTest otherArgComparison
where
    nullCheck.getAnOperand() instanceof NullLiteral
    and checksNull = nullCheck.polarity()
    and equalsCall.getMethod() instanceof EqualsMethod
    and accessSameVarOfSameOwner(nullCheck.getAnOperand(), equalsCall.getQualifier())
    and accessSameVarOfSameOwner(otherArgComparison.getAnOperand(), equalsCall.getArgument(0))
    and (
        // Either directly compares with null
        otherArgComparison.getAnOperand() instanceof NullLiteral
        // Or compares with `equals` call qualifier which is known to be null
        or accessSameVarOfSameOwner(otherArgComparison.getAnOperand(), equalsCall.getQualifier())
    )
    and conditionBlock.controls(otherArgComparison.getBasicBlock(), checksNull)
    and conditionBlock.controls(equalsCall.getBasicBlock(), checksNull.booleanNot())
select equalsCall, "equals(Object) call guarded by $@ null check can be replaced with Objects.equals(Object, Object)", nullCheck, "this"
