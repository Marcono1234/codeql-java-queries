/**
 * Finds unit tests which call one of the standard `Object` methods, such as `equals(Object)`,
 * on the test class itself. Such calls might indicate a bug in the test because they don't
 * perform a test on the class to test.
 * 
 * For example:
 * ```java
 * class MyClassTest {
 *     @Test
 *     void testEquals() {
 *         MyClass obj = new MyClass();
 *         // Bad: Calls `MyClassTest.equals` which uses `Object.equals` implementation
 *         // checking for reference equality and therefore does not test `MyClass` implementation
 *         assertFalse(new MyClassTest().equals(obj));
 *     }
 * }
 * ```
 */

// TODO: This issue might actually be pretty rare; so maybe this query is not needed

import java
import lib.Expressions

class MethodUsage extends Expr {
    Method m;
    RefType receiverType;
    
    MethodUsage() {
        exists(CallableReferencingExpr referencingExpr | referencingExpr = this |
            m = referencingExpr.getReferencedCallable()
            and receiverType = referencingExpr.getReceiverType()
        )
    }
    
    Method getMethod() {
        result = m
    }
    
    RefType getReceiverType() {
        result = receiverType
    }
}

from MethodUsage standardMethodUsage, Method standardMethod
where
    standardMethod = standardMethodUsage.getMethod()
    and (
        standardMethod instanceof EqualsMethod
        or standardMethod instanceof HashCodeMethod
        or standardMethod instanceof CloneMethod
        or standardMethod instanceof ToStringMethod
    )
    // Don't check for CodeQL's TestClass because that also matches when an enclosing class has
    // test methods, causing false positives
    and standardMethodUsage.getReceiverType().getAMethod() instanceof TestMethod
    // Method is not overridden
    and standardMethod.getDeclaringType() instanceof TypeObject
select standardMethodUsage, "Calls method of test class instead of tested object"
