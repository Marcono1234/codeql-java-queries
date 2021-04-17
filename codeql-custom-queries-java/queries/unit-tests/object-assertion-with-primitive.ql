/**
 * Finds calls to assertion methods performing checks on object references,
 * such as reference equality or `null` checks, where an argument is of
 * a primitive type.
 * 
 * Because the primitive value will be wrapped in the boxed type, it will
 * never be `null`, so any `null` checks are pointless. Similarly in most
 * cases a new boxed type instance will be created so any reference equality
 * checks are pointless as well.
 * 
 * E.g.:
 * ```java
 * int unexpected = ...;
 * int actual = ...;
 * // BAD: Method signature is assertNotSame(Object, Object) so primitive
 * // values will be boxed and therefore most likely never be the same reference
 * assertNotSame(unexpected, actual);
 * ```
 */

import java
import lib.AssertLib

from MethodAccess assertCall, AssertMethod assertMethod, Expr primitiveExpr
where
    assertCall.getMethod() = assertMethod
    and (
        assertMethod instanceof AssertNullnessMethod
        or assertMethod instanceof AssertIdentityMethod
    )
    and assertCall.getArgument(assertMethod.getAnInputParamIndex()) = primitiveExpr
    and primitiveExpr.getType() instanceof PrimitiveType
select assertCall, "Performs object assertion on $@ expression of primitive type", primitiveExpr, "this"
