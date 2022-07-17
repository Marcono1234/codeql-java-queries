/**
 * Finds creation of `Calendar` (or its subclass `GregorianCalendar`) with non-constant date values,
 * but where the `Calendar` instance is not made strict. By default `Calendar` is lenient and accepts
 * invalid dates, such as February 34, which are then later converted when date information is
 * retrieved again. To protect against bugs and malicious input `setLenient(false)` can be used
 * to prevent such invalid dates.
 * 
 * See the "Leniency" section of the [`Calendar`](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/Calendar.html)
 * documentation.
 */

import java
import semmle.code.java.dataflow.DataFlow

class TypeGregorianCalendar extends Class {
    TypeGregorianCalendar() {
        hasQualifiedName("java.util", "GregorianCalendar")
    }
}

class CalendarGetInstanceMethod extends Method {
    CalendarGetInstanceMethod() {
        getDeclaringType().hasQualifiedName("java.util", "Calendar")
        and isStatic()
        and hasName("getInstance")
    }
}

class ConstantExpr extends Expr {
    ConstantExpr() {
        this instanceof CompileTimeConstantExpr
        or exists(Field f | f = this.(FieldRead).getField() |
            f.isFinal()
            and f.isStatic()
        )
    }
}

from Expr newExpr
where
    (
        newExpr.(ClassInstanceExpr).getConstructedType() instanceof TypeGregorianCalendar
        or newExpr.(MethodAccess).getMethod() instanceof CalendarGetInstanceMethod
    )
    and not exists(MethodAccess setLenientCall |
        setLenientCall.getMethod().hasStringSignature("setLenient(boolean)")
        and DataFlow::localExprFlow(newExpr, setLenientCall.getQualifier())
    )
    // To reduce false positives make sure a date field is set to a non-constant value
    and (
        exists(Expr arg | arg = newExpr.(ClassInstanceExpr).getAnArgument() |
            arg.getType().hasName(["int", "Integer"])
            and not arg instanceof ConstantExpr
        )
        or exists(MethodAccess setCall |
            setCall.getMethod().hasName(["set", "setWeekDate"])
            and exists(Expr arg | arg = setCall.getAnArgument() |
                arg.getType().hasName(["int", "Integer"])
                and not arg instanceof ConstantExpr
            )
            and DataFlow::localExprFlow(newExpr, setCall.getQualifier())
        )
    )
    and not newExpr.getEnclosingCallable().getDeclaringType() instanceof TestClass
select newExpr, "Calendar instance is lenient"
