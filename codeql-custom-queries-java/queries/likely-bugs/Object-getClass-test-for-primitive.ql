/**
 * Finds `Object.getClass()` calls which compare the result with
 * a primitive type literal, e.g.:
 * ```java
 * obj.getClass() == int.class
 * ```
 *
 * Primitives do not exist as `Object` (only their boxed representation
 * does), therefore these checks will always fail.
 * 
 * @kind problem
 */

import java

class PrimitiveOrVoidType extends Type {
    PrimitiveOrVoidType() {
        this instanceof PrimitiveType
        or this instanceof VoidType
    }
}

from EqualityTest eqTest, MethodAccess getClassCall
where
    getClassCall.getMethod().hasStringSignature("getClass()")
    and eqTest.getAnOperand() = getClassCall
    and eqTest.getAnOperand().(TypeLiteral).getReferencedType() instanceof PrimitiveOrVoidType
select eqTest, "`getClass()` will never return primitive class"
