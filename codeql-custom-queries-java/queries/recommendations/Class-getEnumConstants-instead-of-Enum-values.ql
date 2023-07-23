/**
 * Finds usage of `Class.getEnumConstants()` called on a type literal, for example
 * `MyEnum.class.getEnumConstants()`. Such code should be replaced with a call to
 * the synthetic `values()` method of the enum type, which behaves the same but is
 * more concise and possibly also slightly faster. For example `MyEnum.values()`.
 * 
 * @kind problem
 */

// Inspired by https://bugs.openjdk.org/browse/JDK-8273140

import java

class GetEnumConstantsMethod extends Method {
    GetEnumConstantsMethod() {
        getDeclaringType() instanceof TypeClass
        and hasName("getEnumConstants")
    }
}

from MethodAccess getEnumConstantsCall, EnumType enumType
where
    getEnumConstantsCall.getMethod() instanceof GetEnumConstantsMethod
    and getEnumConstantsCall.getQualifier().(TypeLiteral).getReferencedType() = enumType
select getEnumConstantsCall, "Should use `" + enumType.getName() + ".values()` instead"
