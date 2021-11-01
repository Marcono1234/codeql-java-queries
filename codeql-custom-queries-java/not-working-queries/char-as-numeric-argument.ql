/**
 * Finds call arguments of type `char` or `Character` which are provided for a parameter
 * of a non-character type, for example `int`. This might indicate that the called method
 * or constructor does not treat the argument as character but instead as number, which
 * might be undesired.
 */

// TODO: Has a lot of false positives for deliberate conversion, or when `int` represents code point

import java

// Ignore callables where the numeric parameter represents a code point, or where usage with a
// character is common
class IgnoredCallable extends Callable {
    int ignoredIndex;

    IgnoredCallable() {
        (
            getDeclaringType() instanceof TypeString
            and hasName(["indexOf", "lastIndexOf"])
            and ignoredIndex = 0
        )
        or (
            getDeclaringType().getASourceSupertype*().hasQualifiedName("java.io", "Writer")
            and hasStringSignature("write(int)")
            and ignoredIndex = 0
        )
        or (
            getDeclaringType().getASourceSupertype*().hasQualifiedName("java.io", "DataOutput")
            and hasStringSignature("writeChar(int)")
            and ignoredIndex = 0
        )
        or (
            getDeclaringType().hasQualifiedName("java.lang", "Integer")
            and hasName(["toString", "toHexString"])
            and ignoredIndex = 0
        )
        or (
            getDeclaringType().hasQualifiedName("java.lang", "Character")
            and ignoredIndex = [0..getNumberOfParameters() - 1]
        )
    }

    int getIgnoredParamIndex() {
        result = ignoredIndex
    }
}

from Call call, int argIndex, Expr charArg
where
    call.getArgument(argIndex) = charArg
    and charArg.getType() instanceof CharacterType
    and call.getCallee().getParameterType(argIndex) instanceof NumericType
    and not exists(IgnoredCallable ignored |
        call.getCallee() = ignored
        and argIndex = ignored.getIgnoredParamIndex()
    )
select charArg, "Char argument is provided for parameter of non-char type"
