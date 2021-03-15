/**
 * Finds method calls with a string literal argument representing a single
 * char or code point despite there being a potential alternative method
 * which has a char or code point parameter and likely has better
 * performance. Example:
 * ```
 * int i = str.indexOf(",");
 * // Better performance:
 * int i = str.indexOf(',');
 * ```
 *
 * IMPORTANT: The proposed alternative method is only a guess and might
 * actually have different behavior (e.g. print string representation of
 * int instead of considering it as code point). The javadoc of that method
 * should be carefully examined to verify that this is indeed a suitable
 * alternative.
 */

// NOTE: The performance of this query appears to not be very good

import java

predicate isAtLeastAsVisibleAs(Method m, Method other) {
    m.isPublic()
    or m.isProtected() and not other.isPublic()
    or m.isPackageProtected() and (other.isPackageProtected() or other.isPrivate())
    or m.isPrivate() and other.isPrivate()
}

predicate isCodePointType(Type type) {
    type.(PrimitiveType).getName() = "int"
}

predicate isCharOrCodePointType(Type type) {
    type.(PrimitiveType).getName() = "char"
    or isCodePointType(type)
}

predicate containsSurrogatePair(StringLiteral literal) {
    literal.getValue().length() = 2
    // Matches a unicode escaped high surrogate followed by a low surrogate
    // See https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/lang/Character.html
    and literal.getLiteral().regexpMatch("\"\\\\u[dD][8bB][0-9a-fA-F]{2}\\\\u[dD][cCfF][0-9a-fA-F]{2}\"")
}

predicate isSingleCharOrCodePoint(CompileTimeConstantExpr s, boolean supplementaryCodePoint) {
    (
        s.getStringValue().length() = 1
        and supplementaryCodePoint = false
    )
    or (
        // CompileTimeConstantExpr is string literal or is reading one
        // which represents surrogate pair
        (
            containsSurrogatePair(s)
            or containsSurrogatePair(s.(VarAccess).getVariable().getInitializer())
        )
        and supplementaryCodePoint = true
    )
}

bindingset[requireCodePoint]
Method getCharOrCodePointVariant(Method m, int paramIndex, boolean requireCodePoint) {
    result.getDeclaringType() = m.getDeclaringType().getAnAncestor()
    and result.getName() = m.getName()
    // Either both are static or both are not static
    and (
        (result.isStatic() and m.isStatic())
        or not (result.isStatic() or m.isStatic())
    )
    // Don't consider alternatives with lower visibility, even if they are
    // accessible to the caller
    and isAtLeastAsVisibleAs(result, m)
    // Make sure that all parameters are the same except the string parameter
    // which is a char or code point type
    and m.getNumberOfParameters() = result.getNumberOfParameters()
    and if requireCodePoint = true then (
        isCodePointType(result.getParameterType(paramIndex))
    ) else (
        isCharOrCodePointType(result.getParameterType(paramIndex))
    )
    and forall (int otherParamIndex, Type paramType | otherParamIndex != paramIndex and paramType = m.getParameterType(otherParamIndex) |
        paramType = result.getParameterType(otherParamIndex)
    )
}

from MethodAccess call, int paramIndex, Method potentialAlternative, boolean requireCodePoint
where
    call.getMethod().getParameterType(paramIndex).(RefType).getQualifiedName() in [
        "java.lang.String",
        "java.lang.CharSequence"
    ]
    and isSingleCharOrCodePoint(call.getArgument(paramIndex), requireCodePoint)
    and potentialAlternative = getCharOrCodePointVariant(call.getMethod(), paramIndex, requireCodePoint)
select call, potentialAlternative
