/**
 * Finds methods performing assertions in JUnit 3 test classes, whose signature
 * does not match the default test method signature. That is:
 * - public
 * - `void` return type
 * - no parameters
 * - name starting with `test`
 */

import java
import lib.Tests
import lib.TestsQLInterop

from JUnit38TestClass testClass, Method method, string combinedReason
where
    method.fromSource()
    and testClass.getAMethod() = method
    and exists(MethodAccess assertionCall |
        getEnclosingNonLambdaMethod(assertionCall) = method
        and assertionCall.getMethod() instanceof AssertionMethod
    )
    and combinedReason = strictconcat(string reason |
        not method.isPublic() and reason = "method is not public"
        or not method.getName().matches("test%") and reason = "method name does not start with `test`"
        or not method.getReturnType() instanceof VoidType and reason = "return type is not `void`"
        or method.getNumberOfParameters() > 0 and reason = "method has parameters"
    |
        reason, ", "
    )
    // And no setName(String) call which specifies test method name
    and not exists(MethodAccess setNameCall, Method m |
        m = setNameCall.getMethod()
        and m.hasStringSignature("setName(String)")
        and setNameCall.getReceiverType().getASourceSupertype*() = testClass
    )
    // And test class instances are not created manually, there test method
    // name might be specified
    and not exists(ClassInstanceExpr newExpr |
        newExpr.getConstructedType().getASourceSupertype*() = testClass
    )
    and not method instanceof InitializerMethod
    // And method is not used as utility method by another other method
    and not exists(method.getAReference())
    and not exists(MemberRefExpr methodRef | methodRef.getReferencedCallable() = method)
    // And does not override a supertype method
    and not exists(Method overridden | method.getSourceDeclaration().overrides(overridden))
select method, "Test method has wrong signature: " + combinedReason
