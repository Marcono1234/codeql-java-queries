/**
 * Finds creation of `Calendar` instances with invalid date field values. The most
 * common pitfalls are:
 * - months start at 0
 * - `Calendar.HOUR` is a 12-hour clock value, `HOUR_OF_DAY` is a 24-hour clock value
 * 
 * Additionally `Calendar` is lenient by default, therefore invalid values just wrap
 * to the next valid value, making it difficult to notice that the values are invalid.
 * `setLenient(false)` can be used to make the instance non-lenient. Alternatively
 * the classes from the `java.time` package (added in Java 8) can be used.
 * 
 * @kind problem
 */

import java

class CalendarType extends Class {
    CalendarType() {
        getSourceDeclaration().getASourceSupertype*().hasQualifiedName("java.util", "Calendar")
    }
}

CompileTimeConstantExpr getInvalidArg(Call call) {
    (
        result = call.getArgument(1)
        and not result.getIntValue() in [0 .. 11]
    )
    or (
        result = call.getArgument(2)
        and (
            not result.getIntValue() in [1 .. 31]
            or exists(int month, int day |
                // + 1 because Calendar month values start at 0
                month = call.getArgument(1).(CompileTimeConstantExpr).getIntValue() + 1
                and day = result.getIntValue()
            |
                month = 1 and day > 31
                or month = 2 and day > 29
                or month = 3 and day > 31
                or month = 4 and day > 30
                or month = 5 and day > 31
                or month = 6 and day > 30
                or month = 7 and day > 31
                or month = 8 and day > 31
                or month = 9 and day > 30
                or month = 10 and day > 31
                or month = 11 and day > 30
                or month = 12 and day > 31
            )
        )
    )
    or (
        result = call.getArgument(3)
        and not result.getIntValue() in [0 .. 23]
    )
    or (
        result = call.getArgument(4)
        and not result.getIntValue() in [0 .. 59]
    )
    or (
        result = call.getArgument(5)
        and not result.getIntValue() in [0 .. 59]
    )
}

// See https://docs.oracle.com/en/java/javase/17/docs/api/constant-values.html#java.util.Calendar.MONTH
bindingset[constantValue, fieldName]
Expr getField(int constantValue, string fieldName) {
    result.(CompileTimeConstantExpr).getIntValue() = constantValue
    or result.(FieldRead).getField().hasName(fieldName)
}

from CompileTimeConstantExpr arg
where
    exists(MethodAccess setCall, Method setMethod |
        setCall.getMethod() = setMethod
        and setMethod.hasName("set")
        and setMethod.getNumberOfParameters() >= 3
        and forall(Type paramType | paramType = setMethod.getAParamType() | paramType.hasName("int"))
        and setMethod.getDeclaringType() instanceof CalendarType
        and arg = getInvalidArg(setCall)
    )
    or exists(MethodAccess setCall, Method setMethod |
        setCall.getMethod() = setMethod
        and setMethod.hasName("set")
        and setMethod.getNumberOfParameters() = 2
        and setMethod.getDeclaringType() instanceof CalendarType
        and arg = setCall.getArgument(1)
        and exists(Expr fieldArg |
            fieldArg = setCall.getArgument(0)
        |
            fieldArg = getField(2, "MONTH")
            and not arg.getIntValue() in [0 .. 11]
            or
            fieldArg = getField(5, ["DAY_OF_MONTH", "DATE"])
            and not arg.getIntValue() in [1 .. 31]
            or
            fieldArg = getField(7, "DAY_OF_WEEK")
            and not arg.getIntValue() in [1 .. 7]
            or
            fieldArg = getField(6, "DAY_OF_YEAR")
            and not arg.getIntValue() in [1 .. 366]
            or
            fieldArg = getField(10, "HOUR")
            and not arg.getIntValue() in [0 .. 11]
            or
            fieldArg = getField(11, "HOUR_OF_DAY")
            and not arg.getIntValue() in [0 .. 23]
            or
            fieldArg = getField(12, "MINUTE")
            and not arg.getIntValue() in [0 .. 59]
            or
            fieldArg = getField(13, "SECOND")
            and not arg.getIntValue() in [0 .. 59]
            or
            fieldArg = getField(14, "MILLISECOND")
            and not arg.getIntValue() in [0 .. 999]
        )
    )
    or exists(ClassInstanceExpr newExpr, Constructor constructor |
        newExpr.getConstructedType().hasQualifiedName("java.util", "GregorianCalendar")
        and constructor = newExpr.getConstructor()
        and forall(Type paramType | paramType = constructor.getAParamType() | paramType.hasName("int"))
        and newExpr.getNumArgument() >= 3
        and arg = getInvalidArg(newExpr)
    )
select arg, "Invalid date field value"
