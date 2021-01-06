/**
 * Finds `Object.getClass()` calls which compare the result with
 * a primitive type literal, e.g.:
 * ```
 * obj.getClass() == int.class
 * ```
 *
 * Primitives do not exist as `Object` (only their boxed representation
 * does), therefore these checks will always fail.
 */

import java

class GetClassMethod extends Method {
    GetClassMethod() {
        getDeclaringType() instanceof TypeObject
        and hasStringSignature("getClass()")
    }
}

from EqualityTest eqTest, MethodAccess getClassCall
where
    exists (GetClassMethod m | getClassCall.getMethod().getSourceDeclaration().overridesOrInstantiates*(m))
    and eqTest.getAnOperand() = getClassCall
    and eqTest.getAnOperand().(TypeLiteral).getType() instanceof PrimitiveType
select eqTest, "Object class test with primitive type."
