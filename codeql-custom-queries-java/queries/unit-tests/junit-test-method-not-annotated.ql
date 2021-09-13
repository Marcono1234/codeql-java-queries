/**
 * Finds methods which appear to be intended as JUnit 4 or JUnit 5 test methods,
 * but which are not annotated with the respective test annotation, for example
 * `@Test`. Such methods will not be executed using the default configuration of
 * JUnit causing test failures to go unnoticed.
 */

import java
import lib.Tests
import lib.AssertLib
import lib.JUnit4
import lib.JUnit5 as JUnit5

from Method method
where
    method.fromSource()
    and exists(MethodAccess assertionCall |
        getEnclosingNonLambdaMethod(assertionCall) = method
    |
        assertionCall.getMethod() instanceof JUnit4AssertionMethod
        or assertionCall.getMethod() instanceof JUnit5AssertionMethod
    )
    and not (
        // JUnit 4 seems to consider only direct annotations, see https://github.com/junit-team/junit4/blob/f3ffe841d994bc2b6155ec132a974f3d90d6bc3e/src/main/java/org/junit/runners/model/TestClass.java#L63
        method.getAnAnnotation().getType() instanceof JUnit4TestMethodAnnotationType
        or JUnit5::hasAnnotationOfType(method, any(JUnit5::JUnit5TestMethodAnnotationType t))
        // Also exclude methods annotated with @TestFactory; might contain lambda performing assertion
        or JUnit5::hasAnnotationOfType(method, any(JUnit5::JUnit5TestFactoryAnnotationType t))
    )
    and not method.getDeclaringType() instanceof JUnit38TestClass
    and not method instanceof InitializerMethod
    // And method is not used as utility method by another other method
    and not exists(method.getAReference())
    and not exists(MemberRefExpr methodRef | methodRef.getReferencedCallable() = method)
    // And does not override a supertype method
    and not exists(Method overridden | method.getSourceDeclaration().overrides(overridden))
select method, "Is missing JUnit test annotation"
