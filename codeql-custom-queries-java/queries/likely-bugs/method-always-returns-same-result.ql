/**
 * Finds methods which have multiple `return` statements which all return the same
 * constant value. This might indicate a bug in the logic and suggests that one
 * of the `return` statements should return a different value. Or it indicates that
 * the result of the method is redundant.
 */

// Might have some false positives for multi-module Maven and multi-project Gradle
// projects due to https://github.com/github/codeql/issues/5734

import java

newtype TValueType = TString() or TBoolean() or TIntegral() or TFloatingPoint() or TNull() or TConstantField()

from Method m, string returnValue, TValueType type
where
    // Only consider if there are at least two return statements
    count(ReturnStmt r | r.getEnclosingCallable() = m) >= 2
    and forex(ReturnStmt r | r.getEnclosingCallable() = m |
        // TODO: For integral and floating point types might need to make sure that when return type is Object or Number
        // returned value types match exactly, because then returning different primitive types it would create different
        // boxed types, e.g. `return 1.0f` would return Float but `return 1.0` would return Double
        exists(CompileTimeConstantExpr value | value = r.getResult() |
            value.getStringValue() = returnValue
            and type = TString()
            or
            value.getBooleanValue().toString() = returnValue
            and type = TBoolean()
            or
            value.getIntValue().toString() = returnValue
            and type = TIntegral()
            or
            value.(LongLiteral).getValue() = returnValue
            and type = TIntegral()
            or
            // TODO: Display char in result? (but makes it more difficult to consider `int` literal with
            // same value to be equal)
            value.(CharacterLiteral).getCodePointValue().toString() = returnValue
            and type = TIntegral()
            or
            value.(FloatingPointLiteral).getValue() = returnValue
            and type = TFloatingPoint()
            or
            value.(DoubleLiteral).getValue() = returnValue
            and type = TFloatingPoint()
        )
        or
        r.getResult() instanceof NullLiteral
        and returnValue = "null"
        and type = TNull()
        // Ignore if method has Void return type as convenience for caller of method
        and not m.getReturnType().(RefType).hasQualifiedName("java.lang", "Void")
        or
        // Or returns constant field value, e.g. enum constant
        exists(FieldRead read, Field f |
            read = r.getResult()
            and read.getField() = f
            // Constant values are already covered above; avoid duplicate results
            and not read instanceof CompileTimeConstantExpr
            and returnValue = f.getDeclaringType().getName() + "." + f.getName()
            and f.isStatic()
            and f.isFinal()
            and type = TConstantField()
        )
    )
    // Ignore if method overrides other method; then it is forced to have return value,
    // even if that may always be the same value
    and not exists(m.getSourceDeclaration().getASourceOverriddenMethod())
select m, "All return statements of this method return `" + returnValue + "`"
