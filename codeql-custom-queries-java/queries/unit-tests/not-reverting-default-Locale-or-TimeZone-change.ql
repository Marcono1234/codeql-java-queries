/**
 * Finds test classes which change the default `Locale` or `TimeZone`, but do not seem to
 * revert their changes again. Such test implementations are error-prone because they might
 * affect the execution of subsequent unrelated test methods.
 */

import java
import semmle.code.java.dataflow.SSA

abstract class DefaultChangingCall extends MethodAccess {
    abstract string getChangedTypeName();

    abstract predicate isArgumentDefaultValue();
}

Expr getAnAssignedValue(RValue varRead) {
    exists(Variable var |
        var = varRead.getVariable()
        and (
            // Variable is local or static (and qualifier does not matter)
            (var instanceof LocalScopeVariable or var.isStatic())
            and result = var.getAnAssignedValue()
            or
            // Or is access of own field (to reduce false positives)
            exists(FieldWrite varAssign |
                varAssign.getField() = var
                and result = varAssign.getRhs()
                and varAssign.isOwnFieldAccess()
            )
            and varRead.(FieldRead).isOwnFieldAccess()
        )
    )
}

class TypeLocale extends Class {
    TypeLocale() {
        hasQualifiedName("java.util", "Locale")
    }
}

class DefaultLocaleChangingCall extends DefaultChangingCall {
    Expr localeArg;

    DefaultLocaleChangingCall() {
        exists(Method m |
            m = getMethod()
            and m.getDeclaringType() instanceof TypeLocale
            and (
                m.hasStringSignature("setDefault(Locale)")
                and localeArg = getArgument(0)
                or
                m.hasStringSignature("setDefault(Category, Locale)")
                and localeArg = getArgument(1)
            )
        )
    }

    override
    string getChangedTypeName() {
        result = "Locale"
    }

    override
    predicate isArgumentDefaultValue() {
        exists(MethodAccess getDefaultCall, Method m |
            getDefaultCall = getAnAssignedValue(localeArg)
            and m = getDefaultCall.getMethod()
            and m.getDeclaringType() instanceof TypeLocale
            and m.hasStringSignature(["getDefault()", "getDefault(Category)"])
        )
    }
}

class TypeTimeZone extends Class {
    TypeTimeZone() {
        hasQualifiedName("java.util", "TimeZone")
    }
}

class DefaultTimeZoneChangingCall extends DefaultChangingCall {
    Expr timeZoneArg;

    DefaultTimeZoneChangingCall() {
        exists(Method m |
            m = getMethod()
            and m.getDeclaringType() instanceof TypeTimeZone
            and m.hasStringSignature("setDefault(TimeZone)")
            and timeZoneArg = getArgument(0)
        )
    }

    override
    string getChangedTypeName() {
        result = "TimeZone"
    }

    override
    predicate isArgumentDefaultValue() {
        exists(MethodAccess getDefaultCall, Method m |
            getDefaultCall = getAnAssignedValue(timeZoneArg)
            and m = getDefaultCall.getMethod()
            and m.getDeclaringType() instanceof TypeTimeZone
            and m.hasStringSignature("getDefault()")
        )
    }
}

 // TODO: Maybe support detecting usage of JUnit Pioneer annotations which revert Locale and TimeZone change

from TestClass testClass, DefaultChangingCall call, string changedTypeName
where
    call.getEnclosingCallable().getDeclaringType+() = testClass.(TopLevelType)
    and changedTypeName = call.getChangedTypeName()
    and not call.isArgumentDefaultValue()
    and not exists(DefaultChangingCall revertingCall |
        // Consider reverting call in complete test class in case it is in separate teardown method
        revertingCall.getEnclosingCallable().getDeclaringType+() = testClass
        and revertingCall.getChangedTypeName() = changedTypeName
        and revertingCall != call
        // And argument is the previous default value
        and revertingCall.isArgumentDefaultValue()
    )
select call, "Changes default " + changedTypeName + " value, but does not revert it again"
