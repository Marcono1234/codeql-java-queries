/**
 * Finds static methods which have a parameter of the same type as the declaring class, and
 * which could probably converted to an instance method. This often makes the method less
 * verbose and might also make it easier to use it. For example:
 * ```java
 * public class Number {
 *     private int value;
 * 
 *     public static boolean isPositive(Number n) {
 *         return n.value >= 0;
 *     }
 *     // Could instead be implemented as instance method:
 *     public boolean isPositive() {
 *         return value >= 0;
 *     }
 * }
 * ```
 * 
 * @kind problem
 */

import java

from RefType t, Method m, Parameter p
where
    m.fromSource()
    and m.getDeclaringType() = t
    // Don't check source supertype because method cannot be converted to instance method if parameter
    // has parameterized type
    and m.getAParamType() = t
    // Parameter has same type as declaring class
    and p.getType() = t
    and m.isStatic()
    // Ignore if method seems to be utility method which modifies global state
    and not exists(Field staticField, MethodAccess callOnField |
        staticField.getDeclaringType() = t
        and staticField.isStatic()
        and callOnField.getQualifier().(FieldRead).getField() = staticField
        and callOnField.getEnclosingCallable() = m
    )
    // Ignore if parameter of declaring type can be null; check any parameter (instead of specific)
    // to cover case where multiple parameters exist and one is the fallback / default value for another
    and not exists(EqualityTest nullCheck |
        nullCheck.getAnOperand() instanceof NullLiteral
        and nullCheck.getAnOperand().(RValue).getVariable() = m.getAParameter()
    )
select m, "Method could be instance method"
