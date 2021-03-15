/**
 * Finds usage of the `java.util.Date` constructors (or the ones of its
 * subclasses) which take a year as parameter or the `setYear` method where
 * the year argument is not written in the form `year - 1900`. `Date` takes
 * year values relative to 1900 which is error-prone. It is therefore
 * recommended to write year value arguments in that format.
 *
 * See also https://bugs.openjdk.java.net/browse/JDK-8247706
 */

import java

abstract class DateYearCallable extends Callable {
    abstract int getYearParamIndex();
}

class DateConstructor extends DateYearCallable {
    DateConstructor() {
        getDeclaringType().hasQualifiedName("java.util", "Date")
        and getStringSignature() in [
            "Date(int, int, int)",
            "Date(int, int, int, int, int)",
            "Date(int, int, int, int, int, int)"
        ]
    }
    
    override
    int getYearParamIndex() {
        result = 0
    }
}

class SetYearMethod extends DateYearCallable, Method {
    SetYearMethod() {
        getDeclaringType().hasQualifiedName("java.util", "Date")
        and hasStringSignature("setYear(int)")
    }
    
    override
    int getYearParamIndex() {
        result = 0
    }
}

class SqlDateConstructor extends DateYearCallable {
    SqlDateConstructor() {
        getDeclaringType().hasQualifiedName("java.sql", "Date")
        and hasStringSignature("Date(int, int, int)")
    }
    
    override
    int getYearParamIndex() {
        result = 0
    }
}

class SqlTimestampConstructor extends DateYearCallable {
    SqlTimestampConstructor() {
        getDeclaringType().hasQualifiedName("java.sql", "Timestamp")
        and hasStringSignature("Timestamp(int, int, int, int, int, int, int)")
    }
    
    override
    int getYearParamIndex() {
        result = 0
    }
}

from Call call, DateYearCallable callable
where
    (
        callable = call.getCallee()
        or callable = call.getCallee().(Method).getAnOverride()
    )
    and not exists (SubExpr subExpr |
        subExpr = call.getArgument(callable.getYearParamIndex())
        and subExpr.getRightOperand().(CompileTimeConstantExpr).getIntValue() = 1900
    )
select call
