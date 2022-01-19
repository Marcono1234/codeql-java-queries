/**
 * Finds calls of stubbed methods of mocked objects. Such code might indicate that
 * by accident the call is performed on the wrong object, for example because there is
 * variable with a similar name storing a non-mock object. E.g.:
 * ```java
 * MyClass obj1 = mock(MyClass.class);
 * MyClass obj2 = ...; // real object
 * ...
 * // By accident performs call on mock instead of real object
 * assertEquals("some value", obj1.getValue());
 * ```
 * 
 * If the call is done deliberately, it should be checked if the code can be simplified.
 * Because that call only returns the value which was previously configured to be returned
 * (or a default value), it might be easier and cleaner to directly use the same value
 * here as well. E.g.:
 * ```java
 * MyClass mock = mock(MyClass.class);
 * when(mock.getValue()).thenReturn("result");
 * // Call of stubbed method might be irritating
 * List<String> strings = List.of(mock.getValue());
 * ...
 * ```
 * Instead the same value could directly be used:
 * ```java
 * String result = "result";
 * MyClass mock = mock(MyClass.class);
 * when(mock.getValue()).thenReturn(result);
 * List<String> strings = List.of(result);
 * ...
 * ```
 */

import java
import semmle.code.java.dataflow.DataFlow

/**
 * Expression which represents a mocked object which is not configured to call real methods.
 */
abstract class NonRealCallingMockedObjectAccess extends Expr {
}

class TypeMockito extends Class {
    TypeMockito() {
        hasQualifiedName("org.mockito", "Mockito")
    }
}

/**
 * A `mock(...)` call.
 */
class MockCall extends NonRealCallingMockedObjectAccess, MethodAccess {
    MockCall() {
        exists(Method m |
            m = getMethod()
            and m.getDeclaringType() instanceof TypeMockito
            and m.hasName("mock")
        )
        and not exists(Field callsRealMethodsField |
            callsRealMethodsField.getDeclaringType() instanceof TypeMockito
            and callsRealMethodsField.hasName("CALLS_REAL_METHODS")
            and getAnArgument() = callsRealMethodsField.getAnAccess()
        )
    }
}

class MockedVariableAccess extends NonRealCallingMockedObjectAccess, RValue {
    MockedVariableAccess() {
        exists(Variable var |
            var.getAnAccess() = this
            and (
                exists(Annotation mockAnnotation |
                    mockAnnotation = var.getAnAnnotation()
                    and mockAnnotation.getType().hasQualifiedName("org.mockito", "Mock")
                    and not mockAnnotation.getValue("answer").(FieldRead).getField().hasName("CALLS_REAL_METHODS")
                )
                // Or deprecated annotation
                or var.hasAnnotation("org.mockito", "MockitoAnnotations$Mock")
            )
        )
    }
}

/**
 * Method which takes a mock method call as argument and allows stubbing it.
 */
class MockitoStubbingMethod extends Method {
    MockitoStubbingMethod() {
        (
            getDeclaringType() instanceof TypeMockito
            and hasName("when")
        )
        or (
            getDeclaringType().hasQualifiedName("org.mockito", "BDDMockito")
            and hasName("given")
        )
    }
}

predicate isConfiguredToCallRealMethod(Variable var, Method m) {
    // Example: when(mock.call()).thenCallRealMethod()
    exists(MethodAccess stubbedCall, MethodAccess enclosingStubbingCall, MethodAccess callRealMethodDirective |
        stubbedCall.getMethod() = m
        and stubbedCall.getQualifier() = var.getAnAccess()
        // Also consider child expressions in case type casts are used
        and enclosingStubbingCall.getAnArgument().getAChildExpr*() = stubbedCall
        and enclosingStubbingCall.getMethod() instanceof MockitoStubbingMethod
        and callRealMethodDirective.getQualifier() = enclosingStubbingCall
        and callRealMethodDirective.getMethod().hasStringSignature([
            // Mockito
            "thenCallRealMethod()",
            // BDDMockito
            "willCallRealMethod()"
        ])
    )
    // Example: doCallRealMethod().when(mock).call()
    or exists(MethodAccess callRealMethodDirective, Method callRealMethodDirectiveMethod, MethodAccess stubbingStartCall, Method stubbingStartMethod, MethodAccess stubbedCall |
        callRealMethodDirective.getMethod() = callRealMethodDirectiveMethod
        and callRealMethodDirectiveMethod.getDeclaringType() instanceof TypeMockito
        and callRealMethodDirectiveMethod.hasStringSignature("doCallRealMethod()")
        and stubbingStartCall.getMethod() = stubbingStartMethod
        and stubbingStartMethod.getDeclaringType() instanceof TypeMockito
        and stubbingStartMethod.hasName("when")
        and stubbingStartCall.getQualifier() = callRealMethodDirective
        and stubbingStartCall.getAnArgument() = var.getAnAccess()
        and stubbedCall.getMethod() = m
        and stubbedCall.getQualifier() = stubbingStartCall
    )
}

from NonRealCallingMockedObjectAccess mockedAccess, MethodAccess callOnMock, Expr callOnMockQualifier
where
    callOnMockQualifier = callOnMock.getQualifier()
    and DataFlow::localExprFlow(mockedAccess, callOnMockQualifier)
    // Ignore if Mockito calls real method
    and not exists (Variable var |
        var.getAnAccess() = callOnMockQualifier
        and isConfiguredToCallRealMethod(var, callOnMock.getMethod())
    )
    // Ignore if called as argument for stubbing call, e.g. `when(mock.doSomething())...`
    and not exists(MethodAccess enclosingStubbingCall |
        enclosingStubbingCall.getMethod() instanceof MockitoStubbingMethod
        // Also consider child expressions in case type casts are used
        and enclosingStubbingCall.getAnArgument().getAChildExpr*() = callOnMock
    )
select callOnMock, "Calls a stub method of a mocked object"
