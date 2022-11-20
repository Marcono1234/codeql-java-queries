/**
 * Finds calls to `assertNotEquals` and `assertNotSame` where the types of the checked arguments
 * are incompatible and the assertion will therefore likely always succeed.
 * For example the following assertion will always pass:
 * ```java
 * String a = ...;
 * Number b = ...;
 * // Will always pass
 * assertNotEquals(a, b);
 * ```
 * 
 * If the intention is to verify the implementation of the `equals` method, then it should be
 * called explicitly (e.g. `assertFalse(a.equals(b))`) because `assertNotEquals` might return
 * fast without actually calling `equals` (e.g. when one argument is `null`).
 * 
 * @kind problem
 */

import java

import lib.AssertLib

private Type selfOrBoxed(Type t) {
    result = t
    or result = t.(PrimitiveType).getBoxedType()
}

from MethodAccess assertCall, AssertTwoArgumentsMethod assertMethod, Type typeA, Type typeB
where
    assertMethod = assertCall.getMethod()
    and (
        assertMethod instanceof AssertNotEqualsMethod
        or assertMethod instanceof AssertNotSameMethod
    )
    and typeA = assertCall.getArgument(assertMethod.getFixedParamIndex()).getType()
    and typeB = assertCall.getArgument(assertMethod.getAssertionParamIndex()).getType()
    and not exists(Type tA, Type tB | tA = selfOrBoxed(typeA) and tB = selfOrBoxed(typeB) |
        tA = tB
        or tA.(RefType).getSourceDeclaration().getASourceSupertype*() = tB.(RefType).getSourceDeclaration()
        or tA.(RefType).getSourceDeclaration() = tB.(RefType).getSourceDeclaration().getASourceSupertype*()
    )
select assertCall, "Will always succeed because '" + typeA.getName() + "' and '" + typeB.getName() + "' are not subtypes of each other"
