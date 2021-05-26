/**
 * Finds calls to `String.concat(String)` on String literals. It will likely increase
 * readability to use an add expression instead since the fact that String concatenation
 * is performed will be apparent from the String literal on the left side.
 * E.g.:
 * ```java
 * // Should use `"Name: " + name`
 * String r = "Name: ".concat(name);
 * ```
 */

import java

class StringConcatMethod extends Method {
    StringConcatMethod() {
        getDeclaringType() instanceof TypeString
        and hasStringSignature("concat(String)")
    }
}

predicate hasStringLiteralOnRightSide(Expr e) {
    e instanceof StringLiteral
    // Or concat with String as right operand, e.g. `1 + "a"`
    or hasStringLiteralOnRightSide(e.(AddExpr).getRightOperand())
}

from MethodAccess concatCall
where
    concatCall.getMethod() instanceof StringConcatMethod
    and hasStringLiteralOnRightSide(concatCall.getQualifier())
    // Ignore if used as method reference expression, e.g.: `UnaryOperator<String> f = "a"::concat`
    and not any(MemberRefExpr e).asMethod() = concatCall.getEnclosingCallable()
select concatCall, "Could use add expression (`\"...\" + ...`)  to perform String concatenation"
