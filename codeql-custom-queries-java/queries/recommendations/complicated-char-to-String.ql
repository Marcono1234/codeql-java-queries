/**
 * Finds call which create a String from a `char` by first creating an
 * array only containing that single `char`. It would be better to use
 * either `String.valueOf(char)` or `Character.toString(char)` instead
 * which increases readability and possibly also performance.
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

from ArrayCreationExpr arrayCreation, ArrayInit arrayInit, Expr charExpr, StringFromCharArrayCall stringCreation
where
    arrayCreation.getType().hasName("char[]")
    // Array is created from single char
    and arrayCreation.getInit() = arrayInit
    and arrayInit.getSize() = 1
    and arrayInit.getInit(0) = charExpr
    and DataFlow::localExprFlow(arrayCreation, stringCreation.getCharArrayArg())
    // Note: Character.toString(char) just delegates to String.valueOf(char), so directly using that method
    // might be faster, however its name is possibly not as expressive
select stringCreation, "Creates String from array containing $@ char expression instead of using Character.toString(char)", charExpr, "this"
