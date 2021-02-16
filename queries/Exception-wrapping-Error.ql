/**
 * Finds cases where a class extending `Exception` is wrapping an argument which
 * might be an `java.lang.Error` at runtime.
 * The [documentation](https://docs.oracle.com/en/java/javase/15/docs/api/java.base/java/lang/Error.html)
 * of `Error` says:
 * > An Error is a subclass of Throwable that indicates serious problems that a
 * > reasonable application should not try to catch.
 *
 * Therefore wrapping an `Error` inside an `Exception` lowers its severity and
 * should only be done where absolutely necessary.
 */

import java

abstract class ThrowableWrappingCall extends Call {
    abstract RefType getReceiverType();
    abstract Argument getWrappedThrowableArg();
}

/**
 * Creation of a new exception with a 'cause' exception as argument.
 */
class NewThrowableWithCauseCall extends ThrowableWrappingCall, ClassInstanceExpr {
    private int causeParamIndex;
    
    NewThrowableWithCauseCall() {
        exists(Constructor constructor | constructor = getConstructor() |
            constructor.getDeclaringType().getASourceSupertype*() instanceof TypeThrowable
            and constructor.getParameterType(causeParamIndex).(RefType).getASourceSupertype*() instanceof TypeThrowable
        )
    }
    
    override
    RefType getReceiverType() {
        result = getConstructedType()
    }
    
    override
    Argument getWrappedThrowableArg() {
        result = getArgument(causeParamIndex)
    }
}

/**
 * Call to `initCause(Throwable)` of an exception type.
 */
class InitCauseCall extends ThrowableWrappingCall, MethodAccess {
    InitCauseCall() {
        exists(Method m | m = getMethod() |
            m.getDeclaringType().getASourceSupertype*() instanceof TypeThrowable
            and m.hasStringSignature("initCause(Throwable)")
        )
    }
    
    override
    RefType getReceiverType() {
        result = MethodAccess.super.getReceiverType()
    }
    
    override
    Argument getWrappedThrowableArg() {
        result = getArgument(0)
    }
}

from ThrowableWrappingCall errorWrappingCall, Argument errorArg, string typeName
where
    // Wrapping type is Exception
    errorWrappingCall.getReceiverType().getASourceSupertype*() instanceof TypeException
    and errorArg = errorWrappingCall.getWrappedThrowableArg()
    and (
        // Wrapped type is Error
        typeName = "Error" and errorArg.getType().(RefType).getASourceSupertype*() instanceof TypeError
        // When wrapping argument of type Throwable, the runtime type might be `java.lang.Error`
        or typeName = "Throwable" and errorArg.getType() instanceof TypeThrowable
    )
    // Ignore if wrapped Error is newly created
    and not errorArg instanceof ClassInstanceExpr
    // Ignore if call is inside of constructor for that class, e.g. `initCause(...)`
    // call in constructor
    and not exists(Constructor constructor |
        constructor.getDeclaringType() = errorWrappingCall.getReceiverType()
        and errorWrappingCall.getEnclosingCallable() = constructor
    )
select errorWrappingCall, "Wraps $@ " + typeName + " argument", errorArg, "this"
