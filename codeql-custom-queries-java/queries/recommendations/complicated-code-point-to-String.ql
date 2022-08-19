/**
 * Finds expressions which create a String from a Unicode code point in a complicated
 * way. Instead the method `java.lang.Character.toString(int codePoint)` (added in
 * Java 11) should be used.
 * 
 * @kind problem
 */

import java
import semmle.code.java.dataflow.DataFlow

class StringFromCharArrayCall extends Call {
    StringFromCharArrayCall() {
        exists(Callable callee |
            callee = getCallee()
            and callee.getDeclaringType() instanceof TypeString
        |
            callee.(Constructor).hasStringSignature("String(char[])")
            or callee.(Method).hasStringSignature(["copyValueOf(char[])", "valueOf(char[])"])
        )
    }

    Expr getCharArrayArg() {
        result = getArgument(0)
    }
}

class CharacterCodePointToCharsCall extends MethodAccess {
    CharacterCodePointToCharsCall() {
        exists(Method m | m = getMethod() |
            m.getDeclaringType().hasQualifiedName("java.lang", "Character")
            and m.hasStringSignature("toChars(int)")
        )
    }

    Expr getCodePointArg() {
        result = getArgument(0)
    }
}

class StringBuilderAppendCodePointCall extends MethodAccess {
    StringBuilderAppendCodePointCall() {
        exists(Method m | m = getMethod() |
            m.getDeclaringType() instanceof StringBuildingType
            and m.hasStringSignature("appendCodePoint(int)")
        )
    }

    Expr getCodePointArg() {
        result = getArgument(0)
    }
}

predicate buildsCodePointString(MethodAccess call, Expr codePointArg) {
    exists(ClassInstanceExpr newStringBuilder, StringBuilderAppendCodePointCall appendCodePoint |
        call.getMethod().hasStringSignature("toString()")
        and call.getQualifier() = appendCodePoint
        and codePointArg = appendCodePoint.getCodePointArg()
        and appendCodePoint.getQualifier() = newStringBuilder
        and newStringBuilder.getConstructedType() instanceof StringBuildingType
    )
}

from Expr buildingExpr, Expr codePointExpr
where
    buildsCodePointString(buildingExpr, codePointExpr)
    or exists(CharacterCodePointToCharsCall toCharsCall |
        toCharsCall.getCodePointArg() = codePointExpr
        and DataFlow::localExprFlow(toCharsCall, buildingExpr.(StringFromCharArrayCall).getCharArrayArg())
    )
select buildingExpr, "Builds String from $@ code point expression instead of using Character.toString(int codePoint)", codePointExpr, "this"
